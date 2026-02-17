@testable import BabyLoading
import Foundation
import Testing

@MainActor
struct BabyLoadingViewModelTests {
    private var viewModel: BabyProgressViewModel
    private var mockRepository: MockRepository
    private var mockReloader: MockWidgetReloader

    init() async throws {
        let repo = MockRepository()
        let reloader = MockWidgetReloader()
        mockRepository = repo
        mockReloader = reloader
        viewModel = BabyProgressViewModel(repository: repo, widgetReloader: reloader)
    }

    @Test func updateDate_UpdatesRepositoryAndState() async throws {
        let newDate = Date.now
        mockRepository.daysRemaining = 5
        mockRepository.pregnancyWeek = 20
        mockRepository.babySize = .banana

        viewModel.updateDate(newDate)

        #expect(viewModel.lastPeriodDate == newDate)
        #expect(mockRepository.setEventDateCalled)
        #expect(mockRepository.eventDate == newDate)
        #expect(mockRepository.daysUntilEventCalled)
        #expect(mockRepository.daysRemaining == 5)

        #expect(mockRepository.getPregnancyWeekCalled)
        #expect(viewModel.pregnancyWeek == 20)

        #expect(mockRepository.getBabySizeCalled)
        #expect(viewModel.babySizeString == "un plátano")

        #expect(mockReloader.reloadAllTimelinesCalled)
    }

    @Test func savePhoto_UpdatesStateAndRepository() async throws {
        let fakeData = Data([0xFF, 0xD8, 0xFF, 0xE0])

        viewModel.savePhoto(fakeData)

        #expect(viewModel.photoData == fakeData)
        #expect(mockRepository.savePhotoCalled)
        #expect(mockRepository.storedPhotoData == fakeData)
    }

    @Test func deletePhoto_ClearsStateAndRepository() async throws {
        let fakeData = Data([0xFF, 0xD8, 0xFF, 0xE0])
        viewModel.savePhoto(fakeData)

        viewModel.deletePhoto()

        #expect(viewModel.photoData == nil)
        #expect(mockRepository.deletePhotoCalled)
        #expect(mockRepository.storedPhotoData == nil)
    }
}
