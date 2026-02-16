@testable import BabyLoading
import Testing
import Foundation

struct BabyLoadingRepositoryTests {
    private var repository: BabyProgressRepository
    private var mockDataSource: MockDataSource

    init() {
        let dataSource = MockDataSource()
        self.mockDataSource = dataSource
        self.repository = BabyProgressRepository(dataSource: dataSource)
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
        let today = Date.now
        guard let futureDate = calendar.date(byAdding: .day, value: 5, to: today) else {
            Issue.record("Could not create future date")
            return
        }
        mockDataSource.storedDate = futureDate

        let days = repository.daysUntilEvent()

        #expect(days == 5)
    }

    @Test func daysUntilEvent_WhenDateInPast_ReturnsZero() {
        let calendar = Calendar.current
        let today = Date.now
        guard let pastDate = calendar.date(byAdding: .day, value: -5, to: today) else {
            Issue.record("Could not create past date")
            return
        }
        mockDataSource.storedDate = pastDate

        let days = repository.daysUntilEvent()

        #expect(days == 0)
    }

    @Test func daysUntilEvent_WhenNoDate_ReturnsNil() {
        mockDataSource.storedDate = nil

        let days = repository.daysUntilEvent()

        #expect(days == nil)
    }
}
