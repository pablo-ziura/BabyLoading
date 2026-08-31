import AppLocalization
import BabyLoadingInfrastructure
import BabyLoadingNavigation
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
        outputHandler: { [weak self] output in
            await self?.handleSettingsOutput(output)
        }
    )

    private let dependencyContainer: DependencyContainer
    @ObservationIgnored private var appliedLanguage: AppLanguage
    @ObservationIgnored private var lifecycleState = LifecycleState.notStarted

    init() {
        let dependencyContainer = DependencyContainer()
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
            photoLibraryExporter: PhotoLibraryExporter()
        )
    }

    func start(asOf date: Date = .now) async {
        guard lifecycleState == .notStarted else { return }

        lifecycleState = .starting
        await reloadEveryFeature(asOf: date)
        lifecycleState = .started
    }

    func applicationDidBecomeActive(asOf date: Date = .now) async {
        guard lifecycleState == .started else { return }

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
            await reloadEveryFeature(asOf: .now)
            dependencyContainer.widgetReloader.reloadAllTimelines()
        }
    }

    private func reloadEveryFeature(asOf date: Date) async {
        await dashboardViewModel.reload(asOf: date)
        await journeyViewModel.reload(asOf: date)
        await galleryViewModel.reload(asOf: date)
        await settingsViewModel.reload(asOf: date, preferredLanguages: preferredLanguages)
    }
}
