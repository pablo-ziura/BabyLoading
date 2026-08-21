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

    @MainActor let coordinator = AppCoordinator()

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

    static func makeWidgetContext() -> (repository: BabyProgressRepositoryProtocol, language: AppLanguage) {
        let container = DependencyContainer()
        return (container.repository, container.languageRepository.resolvedLanguage())
    }
}

// MARK: - Navigation Types

enum AppRoute: Hashable {
    case detail(id: String)
    case settings
    // Add more routes as needed
}

enum TabItem: String, CaseIterable, Identifiable {
    case dashboard
    case journey
    case gallery
    case settings

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .dashboard: "tabs.dashboard"
        case .journey: "tabs.journey"
        case .gallery: "tabs.gallery"
        case .settings: "tabs.settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "heart.fill"
        case .journey: return "map.fill"
        case .gallery: return "photo.on.rectangle.fill"
        case .settings: return "gearshape.fill"
        }
    }
}
