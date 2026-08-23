@testable import BabyLoading
import AppLocalization
import Foundation
import PregnancyProgress
import Testing

@MainActor
struct BabyLoadingViewModelTests {
    private var viewModel: BabyProgressViewModel
    private var mockLoadProgressUseCase: MockLoadPregnancyProgressUseCase
    private var mockRepository: MockRepository
    private var mockReloader: MockWidgetReloader
    private var mockUpdateDateUseCase: MockUpdateLastPeriodDateUseCase

    init() async throws {
        let loadProgressUseCase = MockLoadPregnancyProgressUseCase()
        let repo = MockRepository()
        let reloader = MockWidgetReloader()
        let updateDateUseCase = MockUpdateLastPeriodDateUseCase()
        mockLoadProgressUseCase = loadProgressUseCase
        mockRepository = repo
        mockReloader = reloader
        mockUpdateDateUseCase = updateDateUseCase
        viewModel = BabyProgressViewModel(
            repository: repo,
            loadPregnancyProgressUseCase: loadProgressUseCase,
            updateLastPeriodDateUseCase: updateDateUseCase,
            initialLanguage: .english,
            appVersion: "1.0",
            widgetReloader: reloader
        )
    }

    @Test func updateDate_UpdatesRepositoryAndState() async throws {
        let newDate = Date.now
        let dueDate = Date(timeIntervalSince1970: 1_800_000_000)
        mockLoadProgressUseCase.result = PregnancyProgress(
            lastPeriodDate: newDate,
            dueDate: dueDate,
            currentWeek: 20,
            daysUntilDueDate: 5
        )
        let weekContent = WeekContent(
            week: 20,
            babySize: .banana,
            babySizeLabel: "un plátano",
            milestoneTitle: "Semana 20",
            keyEvents: ["Evento"],
            physiologicalImpact: nil
        )
        mockRepository.currentWeekContent = weekContent

        await viewModel.updateDate(newDate)

        #expect(viewModel.lastPeriodDate == newDate)
        #expect(mockUpdateDateUseCase.executeCalled)
        #expect(mockUpdateDateUseCase.updatedDate == newDate)
        #expect(mockLoadProgressUseCase.executeCalled)
        #expect(viewModel.estimatedDueDate == dueDate)
        #expect(viewModel.daysRemaining == 5)
        #expect(viewModel.pregnancyWeek == 20)
        #expect(mockRepository.weekContentCalled)
        #expect(mockRepository.requestedWeek == 20)
        #expect(viewModel.currentWeekContent?.babySizeLabel == "un plátano")

        #expect(mockReloader.reloadAllTimelinesCalled)
    }

    @Test func applyContentLanguage_WhenLanguageChanges_ReloadsContent() async throws {
        let spanishContent = WeekContent(
            week: 20,
            babySize: .banana,
            babySizeLabel: "un plátano",
            milestoneTitle: "Semana 20",
            keyEvents: ["Evento"],
            physiologicalImpact: nil
        )
        mockLoadProgressUseCase.result = PregnancyProgress(
            lastPeriodDate: Date(timeIntervalSince1970: 1_700_000_000),
            dueDate: Date(timeIntervalSince1970: 1_724_192_000),
            currentWeek: 20,
            daysUntilDueDate: 140
        )
        mockRepository.updateContentLanguageHandler = { language in
            guard language == .spanish else { return }
            self.mockRepository.currentWeekContent = spanishContent
            self.mockRepository.allWeekContent = [spanishContent]
        }

        let didChangeLanguage = await viewModel.applyContentLanguage(.spanish)

        #expect(didChangeLanguage)
        #expect(viewModel.appLanguage == .spanish)
        #expect(mockRepository.updateContentLanguageCalled)
        #expect(mockRepository.selectedContentLanguage == .spanish)
        #expect(mockLoadProgressUseCase.executeCalled)
        #expect(viewModel.currentWeekContent == spanishContent)
        #expect(viewModel.allWeekContent == [spanishContent])
        #expect(!mockReloader.reloadAllTimelinesCalled)
    }

    @Test func init_ExposesInjectedAppVersion() async throws {
        #expect(viewModel.appVersion == "1.0")
    }

    @Test func reloadProgress_WhenLoadingFails_PreservesLastValidState() async throws {
        let lastPeriodDate = Date(timeIntervalSince1970: 1_700_000_000)
        let dueDate = Date(timeIntervalSince1970: 1_724_192_000)
        let content = WeekContent(
            week: 18,
            babySize: .sweetPotato,
            babySizeLabel: "a sweet potato",
            milestoneTitle: "Week 18",
            keyEvents: ["Growth"],
            physiologicalImpact: nil
        )
        mockRepository.currentWeekContent = content
        mockLoadProgressUseCase.result = PregnancyProgress(
            lastPeriodDate: lastPeriodDate,
            dueDate: dueDate,
            currentWeek: 18,
            daysUntilDueDate: 154
        )
        await viewModel.reloadProgress(asOf: lastPeriodDate)

        mockLoadProgressUseCase.error = MockPregnancyProgressError.loadFailed
        await viewModel.reloadProgress(asOf: lastPeriodDate)

        #expect(viewModel.lastPeriodDate == lastPeriodDate)
        #expect(viewModel.estimatedDueDate == dueDate)
        #expect(viewModel.daysRemaining == 154)
        #expect(viewModel.pregnancyWeek == 18)
        #expect(viewModel.currentWeekContent == content)
        #expect(viewModel.pregnancyProgressState == .failed(.loadFailed))
    }

    @Test func updateDate_WhenPersistenceFails_PreservesLastValidState() async throws {
        let lastPeriodDate = Date(timeIntervalSince1970: 1_700_000_000)
        let dueDate = Date(timeIntervalSince1970: 1_724_192_000)
        let content = WeekContent(
            week: 18,
            babySize: .sweetPotato,
            babySizeLabel: "a sweet potato",
            milestoneTitle: "Week 18",
            keyEvents: ["Growth"],
            physiologicalImpact: nil
        )
        mockRepository.currentWeekContent = content
        mockLoadProgressUseCase.result = PregnancyProgress(
            lastPeriodDate: lastPeriodDate,
            dueDate: dueDate,
            currentWeek: 18,
            daysUntilDueDate: 154
        )
        await viewModel.reloadProgress(asOf: lastPeriodDate)
        let progressLoadCallCount = mockLoadProgressUseCase.executeCallCount
        mockUpdateDateUseCase.error = MockPregnancyProgressError.updateFailed

        await viewModel.updateDate(Date(timeIntervalSince1970: 1_710_000_000))

        #expect(mockUpdateDateUseCase.executeCallCount == 1)
        #expect(mockLoadProgressUseCase.executeCallCount == progressLoadCallCount)
        #expect(viewModel.lastPeriodDate == lastPeriodDate)
        #expect(viewModel.estimatedDueDate == dueDate)
        #expect(viewModel.daysRemaining == 154)
        #expect(viewModel.pregnancyWeek == 18)
        #expect(viewModel.currentWeekContent == content)
        #expect(viewModel.pregnancyProgressState == .failed(.updateFailed))
        #expect(!mockReloader.reloadAllTimelinesCalled)
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
            loadPregnancyProgressUseCase: MockLoadPregnancyProgressUseCase(),
            updateLastPeriodDateUseCase: MockUpdateLastPeriodDateUseCase(),
            initialLanguage: .english,
            appVersion: "1.0",
            widgetReloader: widgetReloader
        )
    }
}
