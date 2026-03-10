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
        let weekContent = WeekContent(
            week: 20,
            babySize: .banana,
            babySizeLabel: "un plátano",
            milestoneTitle: "Semana 20",
            keyEvents: ["Evento"],
            physiologicalImpact: nil
        )
        mockRepository.currentWeekContent = weekContent
        mockRepository.allWeekContent = [weekContent]

        viewModel.updateDate(newDate)

        #expect(viewModel.lastPeriodDate == newDate)
        #expect(mockRepository.setEventDateCalled)
        #expect(mockRepository.eventDate == newDate)
        #expect(mockRepository.daysUntilEventCalled)
        #expect(mockRepository.daysRemaining == 5)

        #expect(mockRepository.getPregnancyWeekCalled)
        #expect(viewModel.pregnancyWeek == 20)

        #expect(mockRepository.getCurrentWeekContentCalled)
        #expect(viewModel.currentWeekContent?.babySizeLabel == "un plátano")
        #expect(mockRepository.getAllWeekContentCalled)
        #expect(viewModel.allWeekContent == [weekContent])

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

    @Test func refreshContentIfNeeded_WhenSnapshotChanges_ReloadsWidgetAndState() async throws {
        let updatedContent = WeekContent(
            week: 22,
            babySize: .banana,
            babySizeLabel: "un plátano",
            milestoneTitle: "Semana 22",
            keyEvents: ["Evento"],
            physiologicalImpact: nil
        )
        mockRepository.contentSnapshot = .empty
        mockRepository.refreshContentIfNeededHandler = {
            self.mockRepository.contentSnapshot = PregnancyContentDocument(
                schemaVersion: 1,
                locale: "es",
                revision: 2,
                weeks: [updatedContent]
            )
            self.mockRepository.currentWeekContent = updatedContent
            self.mockRepository.allWeekContent = [updatedContent]
        }

        await viewModel.refreshContentIfNeeded()

        #expect(mockRepository.refreshContentIfNeededCalled)
        #expect(viewModel.currentWeekContent == updatedContent)
        #expect(viewModel.allWeekContent == [updatedContent])
        #expect(mockReloader.reloadAllTimelinesCalled)
    }
}
