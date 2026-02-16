@testable import BabyLoading
import XCTest

@MainActor
class BabyLoadingViewModelTests: XCTestCase {
    var viewModel: BabyProgressViewModel!
    var mockRepository: MockRepository!
    var mockReloader: MockWidgetReloader!

    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockRepository()
        mockReloader = MockWidgetReloader()
        viewModel = BabyProgressViewModel(repository: mockRepository, widgetReloader: mockReloader)
    }

    override func tearDown() async throws {
        viewModel = nil
        mockRepository = nil
        mockReloader = nil
        try await super.tearDown()
    }

    func testUpdateDate_UpdatesRepositoryAndState() {
        let newDate = Date.now
        mockRepository.daysRemaining = 5 // Expect daysRemaining to update after setEventDate
        mockRepository.pregnancyWeek = 20
        mockRepository.babySize = .banana

        viewModel.updateDate(newDate)

        XCTAssertEqual(viewModel.eventDate, newDate)
        XCTAssertTrue(mockRepository.setEventDateCalled)
        XCTAssertEqual(mockRepository.eventDate, newDate)
        XCTAssertTrue(mockRepository.daysUntilEventCalled)
        XCTAssertEqual(mockRepository.daysRemaining, 5)
        
        XCTAssertTrue(mockRepository.getPregnancyWeekCalled)
        XCTAssertEqual(viewModel.pregnancyWeek, 20)
        
        XCTAssertTrue(mockRepository.getBabySizeCalled)
        XCTAssertEqual(viewModel.babySizeString, "un Plátano")
        
        XCTAssertTrue(mockReloader.reloadAllTimelinesCalled)
    }
}
