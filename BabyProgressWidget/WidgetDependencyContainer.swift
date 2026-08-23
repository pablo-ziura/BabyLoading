import AppLocalization
import AppPreferences
import BabyLoadingInfrastructure
import Foundation

@MainActor
final class WidgetDependencyContainer {
    let language: AppLanguage
    let timelineProvider: BabyProgressTimelineProvider

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

        let language = ResolveAppLanguageUseCase().execute(
            preferredLanguages: Bundle.main.preferredLocalizations + Locale.preferredLanguages
        )
        let repository = BabyProgressRepository(
            dataSource: BabyProgressDataSource(
                preferencesStore: preferencesStore,
                fileManager: fileManager,
                containerURL: containerURL
            ),
            contentRepositoryFactory: PregnancyContentRepositoryFactory(
                bundle: .main,
                containerURL: containerURL,
                fileManager: fileManager
            ),
            initialLanguage: language
        )

        self.language = language
        timelineProvider = BabyProgressTimelineProvider(
            repository: repository,
            language: language
        )
    }
}
