import BabyLoadingNavigation
import Foundation
import SwiftUI

@MainActor
class DependencyContainer {
    static let shared = DependencyContainer()

    let dataSource: BabyProgressDataSourceProtocol
    let languageRepository: AppLanguageRepositoryProtocol
    let repository: BabyProgressRepositoryProtocol
    let widgetReloader: WidgetReloaderProtocol
    let appVersionProvider: AppVersionProviding

    // MARK: - Coordinator

    @MainActor let router = AppRouter()

    // MARK: - ViewModel

    @MainActor let viewModel: BabyProgressViewModel

    private init() {
        dataSource = BabyProgressDataSource()
        languageRepository = AppLanguageRepository()
        repository = BabyProgressRepository(
            dataSource: dataSource,
            contentRepositoryFactory: PregnancyContentRepositoryFactory(),
            initialLanguage: languageRepository.resolvedLanguage()
        )
        widgetReloader = DefaultWidgetReloader()
        appVersionProvider = BundleAppVersionProvider()
        viewModel = BabyProgressViewModel(
            repository: repository,
            languageRepository: languageRepository,
            appVersionProvider: appVersionProvider,
            widgetReloader: widgetReloader
        )
    }
}
