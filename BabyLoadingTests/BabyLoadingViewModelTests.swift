@testable import BabyLoading
import Testing
import Foundation

@MainActor
struct BabyLoadingViewModelTests {
    private var viewModel: BabyProgressViewModel
    private var mockRepository: MockRepository
    private var mockReloader: MockWidgetReloader

    init() async throws {
        let repo = MockRepository()
        let reloader = MockWidgetReloader()
        self.mockRepository = repo
        self.mockReloader = reloader
        self.viewModel = BabyProgressViewModel(repository: repo, widgetReloader: reloader)
    }

    @Test func updateDate_UpdatesRepositoryAndState() async throws {
        let newDate = Date.now
        mockRepository.daysRemaining = 5 // Expect daysRemaining to update after setEventDate
        mockRepository.pregnancyWeek = 20
        mockRepository.babySize = .banana

        viewModel.updateDate(newDate)

        #expect(viewModel.eventDate == newDate)
        #expect(mockRepository.setEventDateCalled)
        #expect(mockRepository.eventDate == newDate)
        #expect(mockRepository.daysUntilEventCalled)
        #expect(mockRepository.daysRemaining == 5)
        
        #expect(mockRepository.getPregnancyWeekCalled)
        #expect(viewModel.pregnancyWeek == 20)
        
        #expect(mockRepository.getBabySizeCalled)
        #expect(viewModel.babySizeString == "un Plátano")
        
        #expect(mockReloader.reloadAllTimelinesCalled)
    }
}
