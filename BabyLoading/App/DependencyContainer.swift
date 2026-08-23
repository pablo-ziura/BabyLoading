import Foundation

@MainActor
final class DependencyContainer {
    let dataSource: BabyProgressDataSourceProtocol
    let languageRepository: AppLanguageRepositoryProtocol
    let repository: BabyProgressRepositoryProtocol
    let widgetReloader: WidgetReloaderProtocol
    let appVersionProvider: AppVersionProviding

    init() {
        dataSource = BabyProgressDataSource()
        languageRepository = AppLanguageRepository()
        repository = BabyProgressRepository(
            dataSource: dataSource,
            contentRepositoryFactory: PregnancyContentRepositoryFactory(),
            initialLanguage: languageRepository.resolvedLanguage()
        )
        widgetReloader = DefaultWidgetReloader()
        appVersionProvider = BundleAppVersionProvider()
    }
}
