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

    @Test func weekContent_WhenWeekExists_ReturnsWeekContent() {
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
        let result = repository.weekContent(for: 20)

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
        #expect(mockDataSource.storedUltrasoundPhotos.isEmpty)
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

    @Test func ultrasoundPhotoOperationsRemainSeparateFromBellyTracking() throws {
        let data = Data([0x01, 0x02, 0x03])

        repository.addUltrasoundPhoto(data: data)

        #expect(mockDataSource.addUltrasoundPhotoCalled)
        #expect(mockDataSource.storedBellyTrackingEntries.isEmpty)
        let photo = try #require(repository.fetchUltrasoundPhotos().first)
        #expect(photo.data == data)

        repository.deleteUltrasoundPhoto(id: photo.id)

        #expect(mockDataSource.deleteUltrasoundPhotoCalled)
        #expect(repository.fetchUltrasoundPhotos().isEmpty)
    }
}
