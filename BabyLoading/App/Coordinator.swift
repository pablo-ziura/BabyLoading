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

        self.dependencyContainer = dependencyContainer
        router = AppRouter()
        viewModel = BabyProgressViewModel(
            repository: dependencyContainer.repository,
            initialLanguage: dependencyContainer.initialLanguage,
            appVersion: dependencyContainer.loadAppVersionUseCase.execute(),
            widgetReloader: dependencyContainer.widgetReloader
        )
    }

    func reloadContentForCurrentLanguage() {
        let language = dependencyContainer.resolveAppLanguageUseCase.execute(
            preferredLanguages: Bundle.main.preferredLocalizations + Locale.preferredLanguages
        )

        guard viewModel.applyContentLanguage(language) else {
            return
        }

        dependencyContainer.widgetReloader.reloadAllTimelines()
    }
}
