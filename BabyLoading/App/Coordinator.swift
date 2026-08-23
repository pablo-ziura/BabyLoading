import AppLocalization
import BabyLoadingInfrastructure
import BabyLoadingNavigation
import Foundation
import Observation

@MainActor
@Observable
final class Coordinator {
    let router: AppRouter
    let viewModel: BabyProgressViewModel

    private let dependencyContainer: DependencyContainer

    init() {
        let dependencyContainer = DependencyContainer()
        let contentUseCases = dependencyContainer.makePregnancyContentUseCases(
            for: dependencyContainer.initialLanguage
        )

        self.dependencyContainer = dependencyContainer
        router = AppRouter()
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
        await viewModel.reloadUltrasoundPhotos()
        await viewModel.reloadBellyTrackingState()
    }

    func reloadContentForCurrentLanguage() async {
        let language = dependencyContainer.resolveAppLanguageUseCase.execute(
            preferredLanguages: Bundle.main.preferredLocalizations + Locale.preferredLanguages
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

        dependencyContainer.widgetReloader.reloadAllTimelines()
    }
}
