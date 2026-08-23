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

    @Test func reloadContentForCurrentLanguage_WhenSystemLanguageChanges_ReloadsContentAndWidget() async throws {
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

        mockLanguageRepository.systemLanguage = .spanish

        viewModel.reloadContentForCurrentLanguage()

        #expect(viewModel.appLanguage == .spanish)
        #expect(mockRepository.updateContentLanguageCalled)
        #expect(mockRepository.selectedContentLanguage == .spanish)
        #expect(viewModel.currentWeekContent == spanishContent)
        #expect(viewModel.allWeekContent == [spanishContent])
        #expect(mockReloader.reloadAllTimelinesCalled)
    }

    @Test func init_ExposesInjectedAppVersion() async throws {
        #expect(viewModel.appVersion == "1.0")
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

        let viewModel = makeViewModel(
            repository: repository,
            widgetReloader: MockWidgetReloader()
        )

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
        #expect(viewModel.ultrasoundPhotos.isEmpty)
    }

    @Test func ultrasoundPhotoOperations_UpdateOnlyUltrasoundState() async throws {
        let fakeData = Data([0x0F, 0x0E, 0x0D])

        viewModel.addUltrasoundPhoto(fakeData)

        let photo = try #require(viewModel.ultrasoundPhotos.first)
        #expect(mockRepository.addUltrasoundPhotoCalled)
        #expect(photo.data == fakeData)
        #expect(viewModel.bellyTrackingEntries.isEmpty)

        viewModel.deleteUltrasoundPhoto(id: photo.id)

        #expect(mockRepository.deleteUltrasoundPhotoCalled)
        #expect(viewModel.ultrasoundPhotos.isEmpty)
    }

    @Test func updateBellyTrackingCadence_UpdatesStateAndStatus() async throws {
        let calendar = Calendar.current
        let referenceDate = Date.now
        let capturedAt = try #require(calendar.date(byAdding: .day, value: -10, to: referenceDate))
        let entry = BellyTrackingEntry(
            imageFileName: "tracking.jpg",
            capturedAt: capturedAt,
            pregnancyWeekAtCapture: 20
        )
        mockRepository.storedBellyTrackingEntries = [entry]
        mockRepository.storedBellyTrackingSettings = BellyTrackingSettings(intervalDays: 14)
        let trackingViewModel = makeViewModel(
            repository: mockRepository,
            widgetReloader: mockReloader
        )
        let initialDueDate = try #require(
            calendar.date(byAdding: .day, value: 14, to: calendar.startOfDay(for: capturedAt))
        )

        #expect(trackingViewModel.bellyTrackingStatus(asOf: referenceDate) == .upToDate(nextDueDate: initialDueDate))

        trackingViewModel.updateBellyTrackingCadence(intervalDays: 7)

        #expect(mockRepository.saveBellyTrackingSettingsCalled)
        #expect(mockRepository.storedBellyTrackingSettings == BellyTrackingSettings(intervalDays: 7))
        #expect(trackingViewModel.bellyTrackingSettings == BellyTrackingSettings(intervalDays: 7))
        let updatedDueDate = try #require(
            calendar.date(byAdding: .day, value: 7, to: calendar.startOfDay(for: capturedAt))
        )
        #expect(trackingViewModel.bellyTrackingStatus(asOf: referenceDate) == .pending(nextDueDate: updatedDueDate))
    }

    @Test func deleteBellyTrackingEntry_WhenRemovingLastEntry_ClearsDerivedState() async throws {
        let entry = BellyTrackingEntry(
            imageFileName: "tracking.jpg",
            capturedAt: Date.now,
            pregnancyWeekAtCapture: 18
        )
        mockRepository.storedBellyTrackingEntries = [entry]
        mockRepository.storedBellyTrackingImages[entry.imageFileName] = Data([0xAA])
        let freshViewModel = makeViewModel(
            repository: mockRepository,
            widgetReloader: mockReloader
        )

        freshViewModel.deleteBellyTrackingEntry(id: entry.id)

        #expect(mockRepository.deleteBellyTrackingEntryCalled)
        #expect(freshViewModel.bellyTrackingEntries.isEmpty)
        #expect(freshViewModel.lastBellyTrackingEntry == nil)
        #expect(freshViewModel.lastBellyTrackingImageData == nil)
        #expect(freshViewModel.bellyTrackingStatus(asOf: .now) == .needsInitialCapture)
    }

    private func makeViewModel(
        repository: BabyProgressRepositoryProtocol,
        widgetReloader: WidgetReloaderProtocol
    ) -> BabyProgressViewModel {
        BabyProgressViewModel(
            repository: repository,
            languageRepository: MockAppLanguageRepository(),
            appVersionProvider: MockAppVersionProvider(version: "1.0"),
            widgetReloader: widgetReloader
        )
    }
}
