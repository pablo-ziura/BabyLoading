import Foundation
import SwiftUI

@MainActor
class DependencyContainer {
    static let shared = DependencyContainer()

    let dataSource: BabyProgressDataSourceProtocol
    let contentRepository: PregnancyContentRepositoryProtocol
    let repository: BabyProgressRepositoryProtocol
    let widgetReloader: WidgetReloaderProtocol

    // MARK: - Coordinator

    @MainActor let coordinator = AppCoordinator()

    // MARK: - ViewModel

    @MainActor let viewModel: BabyProgressViewModel

    private init() {
        let contentLocalization = PregnancyContentLocalization(bundle: .main)

        dataSource = BabyProgressDataSource()
        contentRepository = PregnancyContentRepository(
            expectedLocale: contentLocalization.localeCode,
            bundleSource: BundleContentSource(bundle: .main, localization: contentLocalization),
            cacheStore: SharedContentCacheStore(localization: contentLocalization),
            remoteSource: RemoteContentSource(
                session: .shared,
                url: Bundle.main.pregnancyContentRemoteURL(localeCode: contentLocalization.localeCode),
                expectedLocale: contentLocalization.localeCode
            )
        )
        repository = BabyProgressRepository(
            dataSource: dataSource,
            contentRepository: contentRepository
        )
        widgetReloader = DefaultWidgetReloader()
        viewModel = BabyProgressViewModel(repository: repository, widgetReloader: widgetReloader)
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

    var title: String {
        switch self {
        case .dashboard: return String(localized: "tabs.dashboard", defaultValue: "Home")
        case .journey: return String(localized: "tabs.journey", defaultValue: "My Journey")
        case .gallery: return String(localized: "tabs.gallery", defaultValue: "Gallery")
        case .settings: return String(localized: "tabs.settings", defaultValue: "Settings")
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
