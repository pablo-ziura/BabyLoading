@testable import BabyLoading
import Foundation
import Testing

struct BabyLoadingRepositoryTests {
    private var repository: BabyProgressRepository
    private var mockDataSource: MockDataSource

    init() {
        let dataSource = MockDataSource()
        mockDataSource = dataSource
        repository = BabyProgressRepository(dataSource: dataSource)
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
}
