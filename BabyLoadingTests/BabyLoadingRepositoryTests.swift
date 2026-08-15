@testable import BabyLoading
import Foundation
import Testing

struct BabyLoadingRepositoryTests {
    private var repository: BabyProgressRepository
    private var mockDataSource: MockDataSource
    private var mockContentRepository: MockPregnancyContentRepository

    init() {
        let dataSource = MockDataSource()
        let contentRepository = MockPregnancyContentRepository()
        mockDataSource = dataSource
        mockContentRepository = contentRepository
        repository = BabyProgressRepository(
            dataSource: dataSource,
            contentRepository: contentRepository
        )
    }

    @Test func getEventDate_WhenDateExists_ReturnsDate() {
        let expectedDate = Date.now
        mockDataSource.storedDate = expectedDate

        let result = repository.getEventDate()

        #expect(result == expectedDate)
        #expect(mockDataSource.fetchCalled)
    }

    @Test func getEventDate_WhenDateDoesNotExist_ReturnsNil() {
        mockDataSource.storedDate = nil

        let result = repository.getEventDate()

        #expect(result == nil)
        #expect(mockDataSource.fetchCalled)
    }

    @Test func setEventDate_SavesDate() {
        let date = Date.now

        repository.setEventDate(date)

        #expect(mockDataSource.saveCalled)
        #expect(mockDataSource.storedDate == date)
    }

    @Test func daysUntilEvent_ReturnsCorrectDays() {
        let calendar = Calendar.current
        // Set lastPeriodDate to today -> dueDate will be about 280 days from now
        let lastPeriodDate = Date.now
        mockDataSource.storedDate = lastPeriodDate

        // Expected calculation
        let dueDate = PregnancyCalculator.calculateDueDate(lastPeriod: lastPeriodDate)
        let startOfToday = calendar.startOfDay(for: .now)
        let startOfDueDate = calendar.startOfDay(for: dueDate)
        let expectedDays = max(0, calendar.dateComponents([.day], from: startOfToday, to: startOfDueDate).day ?? 0)

        let days = repository.daysUntilEvent()

        #expect(days == expectedDays)
    }

    @Test func daysUntilEvent_WhenDueDateIsInPast_ReturnsZero() {
        let calendar = Calendar.current
        let today = Date.now
        // Set lastPeriodDate 300 days ago -> dueDate should be in the past
        guard let pastLastPeriod = calendar.date(byAdding: .day, value: -300, to: today) else {
            Issue.record("Could not create past date")
            return
        }
        mockDataSource.storedDate = pastLastPeriod

        let days = repository.daysUntilEvent()

        #expect(days == 0)
    }

    @Test func daysUntilEvent_WhenNoDate_ReturnsNil() {
        mockDataSource.storedDate = nil

        let days = repository.daysUntilEvent()

        #expect(days == nil)
    }

    @Test func getCurrentWeekContent_WhenWeekExists_ReturnsWeekContent() {
        let calendar = Calendar.current
        let content = WeekContent(
            week: 20,
            babySize: .sweetPotato,
            babySizeLabel: "un boniato",
            milestoneTitle: "Semana 20",
            keyEvents: ["Evento"],
            physiologicalImpact: "Impacto"
        )
        mockContentRepository.snapshot = PregnancyContentDocument(
            schemaVersion: 1,
            locale: "es",
            revision: 1,
            weeks: [content]
        )
        mockDataSource.storedDate = calendar.date(byAdding: .day, value: -(20 * 7), to: .now)

        let result = repository.getCurrentWeekContent()

        #expect(result == content)
    }

    @Test func getAllWeekContent_ReturnsAllContent() {
        let content = WeekContent(
            week: 22,
            babySize: .banana,
            babySizeLabel: "un plátano",
            milestoneTitle: "Semana 22",
            keyEvents: ["Evento"],
            physiologicalImpact: nil
        )
        mockContentRepository.snapshot = PregnancyContentDocument(
            schemaVersion: 1,
            locale: "es",
            revision: 1,
            weeks: [content]
        )

        let result = repository.getAllWeekContent()

        #expect(result == [content])
    }

    @Test func saveBellyTrackingPhoto_PersistsEntryAndImageData() {
        let capturedAt = Date.now
        let data = Data([0x01, 0x02, 0x03])

        let savedEntry = repository.saveBellyTrackingPhoto(
            data: data,
            capturedAt: capturedAt,
            pregnancyWeekAtCapture: 18
        )

        #expect(mockDataSource.saveBellyTrackingPhotoCalled)
        #expect(savedEntry != nil)
        #expect(mockDataSource.storedBellyTrackingEntries.count == 1)
        #expect(mockDataSource.storedBellyTrackingImages[savedEntry?.imageFileName ?? ""] == data)
        #expect(mockDataSource.storedPhotos == [data])
    }

    @Test func deleteBellyTrackingEntry_RemovesSavedEntry() {
        let entry = BellyTrackingEntry(
            imageFileName: "tracking.jpg",
            capturedAt: Date.now,
            pregnancyWeekAtCapture: 20
        )
        mockDataSource.storedBellyTrackingEntries = [entry]
        mockDataSource.storedBellyTrackingImages[entry.imageFileName] = Data([0x0A])

        repository.deleteBellyTrackingEntry(id: entry.id)

        #expect(mockDataSource.deleteBellyTrackingEntryCalled)
        #expect(mockDataSource.storedBellyTrackingEntries.isEmpty)
        #expect(mockDataSource.storedBellyTrackingImages[entry.imageFileName] == nil)
    }

    @Test func nextBellyTrackingDueDate_UsesLastEntryAndCadence() {
        let calendar = Calendar.current
        let firstCapture = calendar.date(byAdding: .day, value: -20, to: .now)!
        let latestCapture = calendar.date(byAdding: .day, value: -7, to: .now)!
        mockDataSource.storedBellyTrackingEntries = [
            BellyTrackingEntry(
                imageFileName: "first.jpg",
                capturedAt: firstCapture,
                pregnancyWeekAtCapture: 16
            ),
            BellyTrackingEntry(
                imageFileName: "latest.jpg",
                capturedAt: latestCapture,
                pregnancyWeekAtCapture: 18
            ),
        ]
        mockDataSource.storedBellyTrackingSettings = BellyTrackingSettings(intervalDays: 14)

        let dueDate = repository.nextBellyTrackingDueDate()

        #expect(dueDate == calendar.date(byAdding: .day, value: 14, to: latestCapture))
    }
}
