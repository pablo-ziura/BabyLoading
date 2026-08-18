@testable import BabyLoading
import Foundation
import Testing

@MainActor
struct BabyLoadingViewModelTests {
    private var viewModel: BabyProgressViewModel
    private var mockRepository: MockRepository
    private var mockReloader: MockWidgetReloader
    private var mockLanguageRepository: MockAppLanguageRepository

    init() async throws {
        let repo = MockRepository()
        let reloader = MockWidgetReloader()
        let languageRepository = MockAppLanguageRepository()
        mockRepository = repo
        mockReloader = reloader
        mockLanguageRepository = languageRepository
        viewModel = BabyProgressViewModel(
            repository: repo,
            languageRepository: languageRepository,
            appVersionProvider: MockAppVersionProvider(version: "1.0"),
            widgetReloader: reloader
        )
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

    @Test func updateLanguage_PersistsLanguageReloadsContentAndWidget() async throws {
        let spanishContent = WeekContent(
            week: 20,
            babySize: .banana,
            babySizeLabel: "un plátano",
            milestoneTitle: "Semana 20",
            keyEvents: ["Evento"],
            physiologicalImpact: nil
        )
        mockRepository.updateContentLanguageHandler = { language in
            guard language == .spanish else { return }
            self.mockRepository.currentWeekContent = spanishContent
            self.mockRepository.allWeekContent = [spanishContent]
        }

        viewModel.updateLanguage(.spanish)

        #expect(mockLanguageRepository.updateSelectedLanguageCalled)
        #expect(mockLanguageRepository.storedLanguage == .spanish)
        #expect(viewModel.selectedLanguage == .spanish)
        #expect(mockRepository.updateContentLanguageCalled)
        #expect(mockRepository.selectedContentLanguage == .spanish)
        #expect(viewModel.currentWeekContent == spanishContent)
        #expect(viewModel.allWeekContent == [spanishContent])
        #expect(mockReloader.reloadAllTimelinesCalled)
    }

    @Test func init_ExposesInjectedAppVersion() async throws {
        #expect(viewModel.appVersion == "1.0")
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

    @Test func init_LoadsBellyTrackingState() async throws {
        let repository = MockRepository()
        let entry = BellyTrackingEntry(
            imageFileName: "tracking.jpg",
            capturedAt: Date.now,
            pregnancyWeekAtCapture: 21
        )
        repository.storedBellyTrackingEntries = [entry]
        repository.storedBellyTrackingImages[entry.imageFileName] = Data([0x99])
        repository.storedBellyTrackingSettings = BellyTrackingSettings(intervalDays: 14)
        repository.nextBellyTrackingDueDateValue = Calendar.current.date(byAdding: .day, value: 14, to: entry.capturedAt)

        let viewModel = BabyProgressViewModel(repository: repository, widgetReloader: MockWidgetReloader())

        #expect(viewModel.bellyTrackingEntries == [entry])
        #expect(viewModel.bellyTrackingSettings == BellyTrackingSettings(intervalDays: 14))
        #expect(viewModel.lastBellyTrackingEntry == entry)
        #expect(viewModel.lastBellyTrackingImageData == Data([0x99]))
    }

    @Test func saveBellyTrackingPhoto_UpdatesStateAndRepository() async throws {
        mockRepository.pregnancyWeek = 24
        viewModel.pregnancyWeek = 24
        let fakeData = Data([0x0F, 0x0E, 0x0D])

        let didSave = viewModel.saveBellyTrackingPhoto(fakeData)

        #expect(didSave)
        #expect(mockRepository.saveBellyTrackingPhotoCalled)
        #expect(viewModel.bellyTrackingEntries.count == 1)
        #expect(viewModel.lastBellyTrackingEntry?.pregnancyWeekAtCapture == 24)
        #expect(viewModel.lastBellyTrackingImageData == fakeData)
        #expect(viewModel.photosData == [fakeData])
    }

    @Test func updateBellyTrackingCadence_UpdatesStateAndRepository() async throws {
        mockRepository.nextBellyTrackingDueDateValue = Calendar.current.date(byAdding: .day, value: 14, to: .now)

        viewModel.updateBellyTrackingCadence(intervalDays: 14)

        #expect(mockRepository.saveBellyTrackingSettingsCalled)
        #expect(mockRepository.storedBellyTrackingSettings == BellyTrackingSettings(intervalDays: 14))
        #expect(viewModel.bellyTrackingSettings == BellyTrackingSettings(intervalDays: 14))
        #expect(viewModel.nextBellyTrackingDueDate == mockRepository.nextBellyTrackingDueDateValue)
    }

    @Test func deleteBellyTrackingEntry_WhenRemovingLastEntry_ClearsDerivedState() async throws {
        let entry = BellyTrackingEntry(
            imageFileName: "tracking.jpg",
            capturedAt: Date.now,
            pregnancyWeekAtCapture: 18
        )
        mockRepository.storedBellyTrackingEntries = [entry]
        mockRepository.storedBellyTrackingImages[entry.imageFileName] = Data([0xAA])
        mockRepository.nextBellyTrackingDueDateValue = Calendar.current.date(byAdding: .day, value: 7, to: entry.capturedAt)
        let freshViewModel = BabyProgressViewModel(repository: mockRepository, widgetReloader: mockReloader)
        mockRepository.nextBellyTrackingDueDateValue = nil

        freshViewModel.deleteBellyTrackingEntry(id: entry.id)

        #expect(mockRepository.deleteBellyTrackingEntryCalled)
        #expect(freshViewModel.bellyTrackingEntries.isEmpty)
        #expect(freshViewModel.lastBellyTrackingEntry == nil)
        #expect(freshViewModel.lastBellyTrackingImageData == nil)
        #expect(freshViewModel.nextBellyTrackingDueDate == nil)
    }
}
