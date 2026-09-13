import AppLocalization
import BabyLoadingInfrastructure
import BabyLoadingNavigation
import CloudBackup
import DashboardFeature
import Foundation
import GalleryFeature
import JourneyFeature
import SettingsFeature

@MainActor
@Observable
final class Coordinator {
    private enum LifecycleState {
        case notStarted
        case starting
        case started
    }

    let router: AppRouter
    let dashboardViewModel: DashboardViewModel
    let journeyViewModel: JourneyViewModel
    let galleryViewModel: GalleryViewModel

    @ObservationIgnored private(set) lazy var settingsViewModel = SettingsViewModel(
        loadPregnancyProgressUseCase: dependencyContainer.loadPregnancyProgressUseCase,
        updateLastPeriodDateUseCase: dependencyContainer.updateLastPeriodDateUseCase,
        calculateDueDateUseCase: dependencyContainer.calculateDueDateUseCase,
        resolveAppLanguageUseCase: dependencyContainer.resolveAppLanguageUseCase,
        loadAppVersionUseCase: dependencyContainer.loadAppVersionUseCase,
        initialLanguage: dependencyContainer.initialLanguage,
        backupUseCases: dependencyContainer.backupUseCases,
        outputHandler: { [weak self] output in
            await self?.handleSettingsOutput(output)
        }
    )

    private let dependencyContainer: DependencyContainer
    @ObservationIgnored private var appliedLanguage: AppLanguage
    @ObservationIgnored private var lifecycleState = LifecycleState.notStarted
    @ObservationIgnored private var backupObservation: Task<Void, Never>?
    @ObservationIgnored private var lastBackupState = BackupState()
    @ObservationIgnored private var isApplicationActive = true

    convenience init() { self.init(dependencyContainer: DependencyContainer()) }

    init(dependencyContainer: DependencyContainer) {
        let contentUseCases = dependencyContainer.makePregnancyContentUseCases(
            for: dependencyContainer.initialLanguage
        )

        self.dependencyContainer = dependencyContainer
        appliedLanguage = dependencyContainer.initialLanguage
        router = AppRouter()
        dashboardViewModel = DashboardViewModel(
            loadPregnancyProgressUseCase: dependencyContainer.loadPregnancyProgressUseCase,
            loadPregnancyWeekContentUseCase: contentUseCases.loadWeekContent
        )
        journeyViewModel = JourneyViewModel(
            loadPregnancyProgressUseCase: dependencyContainer.loadPregnancyProgressUseCase,
            loadPregnancyTimelineUseCase: contentUseCases.loadTimeline
        )
        galleryViewModel = GalleryViewModel(
            loadPregnancyProgressUseCase: dependencyContainer.loadPregnancyProgressUseCase,
            loadUltrasoundPhotosUseCase: dependencyContainer.loadUltrasoundPhotosUseCase,
            addUltrasoundPhotoUseCase: dependencyContainer.addUltrasoundPhotoUseCase,
            deleteUltrasoundPhotoUseCase: dependencyContainer.deleteUltrasoundPhotoUseCase,
            loadBellyTrackingTimelineUseCase: dependencyContainer.loadBellyTrackingTimelineUseCase,
            loadBellyTrackingImageUseCase: dependencyContainer.loadBellyTrackingImageUseCase,
            captureBellyTrackingPhotoUseCase: dependencyContainer.captureBellyTrackingPhotoUseCase,
            deleteBellyTrackingEntryUseCase: dependencyContainer.deleteBellyTrackingEntryUseCase,
            loadBellyTrackingSettingsUseCase: dependencyContainer.loadBellyTrackingSettingsUseCase,
            updateBellyTrackingSettingsUseCase: dependencyContainer.updateBellyTrackingSettingsUseCase,
            resolveBellyTrackingStatusUseCase: dependencyContainer.resolveBellyTrackingStatusUseCase,
            photoLibraryExporter: PhotoLibraryExporter(),
            retryBackupUseCase: dependencyContainer.backupUseCases.retry
        )
    }

    deinit { backupObservation?.cancel() }

    func start(asOf date: Date = .now) async {
        guard lifecycleState == .notStarted else { return }

        lifecycleState = .starting
        do { try await dependencyContainer.backupRuntime.initialize() } catch {
            var state = BackupState()
            state.failure = (error as? BackupFailure) ?? .storage
            settingsViewModel.applyBackupState(state)
            galleryViewModel.applyBackupState(state)
        }
        let state = dependencyContainer.backupRuntime.state
        settingsViewModel.applyBackupState(state)
        galleryViewModel.applyBackupState(state)
        lastBackupState = state
        await reloadEveryFeature(asOf: date)
        lifecycleState = .started
        backupObservation = Task { [weak self, runtime = dependencyContainer.backupRuntime] in
            for await state in runtime.observeState() {
                guard !Task.isCancelled, let self else { return }
                await self.applyBackupState(state)
            }
        }
        dependencyContainer.widgetReloader.reloadAllTimelines()
        await dependencyContainer.backupRuntime.setActive(isApplicationActive)
    }

    func handleOpenURL(_ url: URL) { dependencyContainer.handleOpenURL(url) }

    func applicationDidResignActive() async {
        isApplicationActive = false
        await dependencyContainer.backupRuntime.setActive(false)
    }

    private func applyBackupState(_ state: BackupState) async {
        let previous = lastBackupState
        lastBackupState = state
        settingsViewModel.applyBackupState(state)
        galleryViewModel.applyBackupState(state)
        if previous.profileID != state.profileID || previous.lastPeriodDay != state.lastPeriodDay {
            await reloadEveryFeature(asOf: .now)
            dependencyContainer.widgetReloader.reloadAllTimelines()
        } else if previous.records != state.records {
            await galleryViewModel.reload(asOf: .now)
        }
    }

    func applicationDidBecomeActive(asOf date: Date = .now) async {
        isApplicationActive = true
        guard lifecycleState == .started else { return }
        await dependencyContainer.backupRuntime.setActive(true)

        let language = dependencyContainer.resolveAppLanguageUseCase.execute(
            preferredLanguages: preferredLanguages
        )
        let languageChanged = language != appliedLanguage

        if languageChanged {
            appliedLanguage = language
            let contentUseCases = dependencyContainer.makePregnancyContentUseCases(for: language)
            await dashboardViewModel.reload(asOf: date, using: contentUseCases.loadWeekContent)
            await journeyViewModel.reload(asOf: date, using: contentUseCases.loadTimeline)
        } else {
            await dashboardViewModel.reload(asOf: date)
            await journeyViewModel.reload(asOf: date)
        }

        await galleryViewModel.reload(asOf: date)
        await settingsViewModel.reload(asOf: date, preferredLanguages: preferredLanguages)

        if languageChanged {
            dependencyContainer.widgetReloader.reloadAllTimelines()
        }
    }

    private var preferredLanguages: [String] {
        Bundle.main.preferredLocalizations + Locale.preferredLanguages
    }

    private func handleSettingsOutput(_ output: SettingsViewModelOutput) async {
        switch output {
        case .lastPeriodDateUpdated:
            do { try await dependencyContainer.backupRuntime.refreshLocalState() } catch {
                var state = dependencyContainer.backupRuntime.state
                state.failure = (error as? BackupFailure) ?? .storage
                settingsViewModel.applyBackupState(state)
            }
        }
    }

    private func reloadEveryFeature(asOf date: Date) async {
        await dashboardViewModel.reload(asOf: date)
        await journeyViewModel.reload(asOf: date)
        await galleryViewModel.reload(asOf: date)
        await settingsViewModel.reload(asOf: date, preferredLanguages: preferredLanguages)
    }
}
