import AppLocalization
import AppPreferences
import BabyLoadingInfrastructure
import Foundation

@MainActor
final class DependencyContainer {
    let dataSource: BabyProgressDataSourceProtocol
    let repository: BabyProgressRepositoryProtocol
    let widgetReloader: WidgetReloaderProtocol
    let resolveAppLanguageUseCase: any ResolveAppLanguageUseCaseProtocol
    let loadAppVersionUseCase: any LoadAppVersionUseCaseProtocol
    let initialLanguage: AppLanguage

    init() {
        let fileManager = FileManager.default
        let preferencesStore: UserDefaultsPreferencesStore
        let containerURL: URL

        do {
            preferencesStore = UserDefaultsPreferencesStore(
                userDefaults: try SharedAppGroup.userDefaults()
            )
            containerURL = try SharedAppGroup.containerURL(fileManager: fileManager)
        } catch {
            preconditionFailure("BabyLoading App Group is unavailable: \(error)")
        }

        let resolveAppLanguageUseCase = ResolveAppLanguageUseCase()
        let initialLanguage = resolveAppLanguageUseCase.execute(
            preferredLanguages: Bundle.main.preferredLocalizations + Locale.preferredLanguages
        )

        dataSource = BabyProgressDataSource(
            preferencesStore: preferencesStore,
            fileManager: fileManager,
            containerURL: containerURL
        )
        repository = BabyProgressRepository(
            dataSource: dataSource,
            contentRepositoryFactory: PregnancyContentRepositoryFactory(
                bundle: .main,
                containerURL: containerURL,
                fileManager: fileManager
            ),
            initialLanguage: initialLanguage
        )
        widgetReloader = DefaultWidgetReloader()
        self.resolveAppLanguageUseCase = resolveAppLanguageUseCase
        loadAppVersionUseCase = LoadAppVersionUseCase(
            provider: BundleAppVersionProvider(bundle: .main)
        )
        self.initialLanguage = initialLanguage
    }
}
