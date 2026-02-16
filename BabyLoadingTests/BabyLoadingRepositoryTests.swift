@testable import BabyLoading
import XCTest

class BabyLoadingRepositoryTests: XCTestCase {
    var repository: BabyProgressRepository!
    var mockDataSource: MockDataSource!

    override func setUp() {
        super.setUp()
        mockDataSource = MockDataSource()
        repository = BabyProgressRepository(dataSource: mockDataSource)
    }

    override func tearDown() {
        repository = nil
        mockDataSource = nil
        super.tearDown()
    }

    func testGetEventDate_WhenDateExists_ReturnsDate() {
        let expectedDate = Date.now
        mockDataSource.storedDate = expectedDate

        let result = repository.getEventDate()

        XCTAssertEqual(result, expectedDate)
        XCTAssertTrue(mockDataSource.fetchCalled)
    }

    func testGetEventDate_WhenDateDoesNotExist_ReturnsNil() {
        mockDataSource.storedDate = nil

        let result = repository.getEventDate()

        XCTAssertNil(result)
        XCTAssertTrue(mockDataSource.fetchCalled)
    }

    func testSetEventDate_SavesDate() {
        let date = Date.now

        repository.setEventDate(date)

        XCTAssertTrue(mockDataSource.saveCalled)
        XCTAssertEqual(mockDataSource.storedDate, date)
    }

    func testDaysUntilEvent_ReturnsCorrectDays() {
        let calendar = Calendar.current
        let today = Date.now
        guard let futureDate = calendar.date(byAdding: .day, value: 5, to: today) else {
            XCTFail("Could not create future date")
            return
        }
        mockDataSource.storedDate = futureDate

        let days = repository.daysUntilEvent()

        XCTAssertEqual(days, 5)
    }

    func testDaysUntilEvent_WhenDateInPast_ReturnsZero() {
        let calendar = Calendar.current
        let today = Date.now
        guard let pastDate = calendar.date(byAdding: .day, value: -5, to: today) else {
            XCTFail("Could not create past date")
            return
        }
        mockDataSource.storedDate = pastDate

        let days = repository.daysUntilEvent()

        XCTAssertEqual(days, 0)
    }

    func testDaysUntilEvent_WhenNoDate_ReturnsNil() {
        mockDataSource.storedDate = nil

        let days = repository.daysUntilEvent()

        XCTAssertNil(days)
    }
}
