import AppLocalization
import BabyLoadingInfrastructure
import BabyLoadingNavigation
import DashboardFeature
import Foundation
import GalleryFeature
import JourneyFeature
import Observation
import SettingsFeature

@MainActor
@Observable
final class Coordinator {
    let router: AppRouter
    let viewModel: BabyProgressViewModel
    let dashboardViewModel: DashboardViewModel
    let journeyViewModel: JourneyViewModel
    let galleryViewModel: GalleryViewModel

    @ObservationIgnored private(set) lazy var settingsViewModel = SettingsViewModel(
        loadPregnancyProgressUseCase: dependencyContainer.loadPregnancyProgressUseCase,
        updateLastPeriodDateUseCase: dependencyContainer.updateLastPeriodDateUseCase,
        resolveAppLanguageUseCase: dependencyContainer.resolveAppLanguageUseCase,
        loadAppVersionUseCase: dependencyContainer.loadAppVersionUseCase,
        initialLanguage: dependencyContainer.initialLanguage,
        outputHandler: { [weak self] output in
            await self?.handleSettingsOutput(output)
        }
    )

    private let dependencyContainer: DependencyContainer

    init() {
        let dependencyContainer = DependencyContainer()
        let contentUseCases = dependencyContainer.makePregnancyContentUseCases(
            for: dependencyContainer.initialLanguage
        )

        self.dependencyContainer = dependencyContainer
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
        viewModel = BabyProgressViewModel(
            loadPregnancyProgressUseCase: dependencyContainer.loadPregnancyProgressUseCase,
            updateLastPeriodDateUseCase: dependencyContainer.updateLastPeriodDateUseCase,
            loadPregnancyWeekContentUseCase: contentUseCases.loadWeekContent,
            loadPregnancyTimelineUseCase: contentUseCases.loadTimeline,
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
            initialLanguage: dependencyContainer.initialLanguage,
            appVersion: dependencyContainer.loadAppVersionUseCase.execute(),
            widgetReloader: dependencyContainer.widgetReloader
        )
    }

    func start() async {
        await viewModel.reloadContent()
        await viewModel.reloadProgress()
        await dashboardViewModel.reload()
        await journeyViewModel.reload()
        await galleryViewModel.reload()
        await settingsViewModel.reload(preferredLanguages: preferredLanguages)
    }

    func reloadContentForCurrentLanguage() async {
        let language = dependencyContainer.resolveAppLanguageUseCase.execute(
            preferredLanguages: preferredLanguages
        )
        guard language != viewModel.appLanguage else {
            return
        }

        let contentUseCases = dependencyContainer.makePregnancyContentUseCases(for: language)
        guard await viewModel.applyContentLanguage(
            language,
            loadPregnancyWeekContentUseCase: contentUseCases.loadWeekContent,
            loadPregnancyTimelineUseCase: contentUseCases.loadTimeline
        ) else {
            return
        }

        await dashboardViewModel.reloadCurrentWeekContent(using: contentUseCases.loadWeekContent)
        await journeyViewModel.reloadTimeline(using: contentUseCases.loadTimeline)
        await settingsViewModel.reload(preferredLanguages: preferredLanguages)
        dependencyContainer.widgetReloader.reloadAllTimelines()
    }

    private var preferredLanguages: [String] {
        Bundle.main.preferredLocalizations + Locale.preferredLanguages
    }

    private func handleSettingsOutput(_ output: SettingsViewModelOutput) async {
        switch output {
        case .lastPeriodDateUpdated:
            await viewModel.reloadContent()
            await viewModel.reloadProgress()
            await dashboardViewModel.reload()
            await journeyViewModel.reload()
            await galleryViewModel.reload()
            await settingsViewModel.reload(preferredLanguages: preferredLanguages)
            dependencyContainer.widgetReloader.reloadAllTimelines()
        }
    }
}
