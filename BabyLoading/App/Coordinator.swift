import BabyLoadingNavigation
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
            languageRepository: dependencyContainer.languageRepository,
            appVersionProvider: dependencyContainer.appVersionProvider,
            widgetReloader: dependencyContainer.widgetReloader
        )
    }
}
