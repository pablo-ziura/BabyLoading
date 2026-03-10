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
        dataSource = BabyProgressDataSource()
        contentRepository = PregnancyContentRepository(
            bundleSource: BundleContentSource(bundle: .main),
            cacheStore: SharedContentCacheStore(),
            remoteSource: RemoteContentSource(
                session: .shared,
                url: Bundle.main.pregnancyContentRemoteURL
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
        case .dashboard: return "Inicio"
        case .journey: return "Mi Viaje"
        case .gallery: return "Galería"
        case .settings: return "Ajustes"
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
