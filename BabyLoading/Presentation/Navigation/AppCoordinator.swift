import SwiftUI

@Observable
class AppCoordinator {
    var selectedTab: TabItem = .dashboard

    var dashboardPath = NavigationPath()
    var journeyPath = NavigationPath()
    var galleryPath = NavigationPath()
    var settingsPath = NavigationPath()

    func push(_ route: AppRoute) {
        switch selectedTab {
        case .dashboard:
            dashboardPath.append(route)
        case .journey:
            journeyPath.append(route)
        case .gallery:
            galleryPath.append(route)
        case .settings:
            settingsPath.append(route)
        }
    }

    func pop() {
        switch selectedTab {
        case .dashboard:
            if !dashboardPath.isEmpty { dashboardPath.removeLast() }
        case .journey:
            if !journeyPath.isEmpty { journeyPath.removeLast() }
        case .gallery:
            if !galleryPath.isEmpty { galleryPath.removeLast() }
        case .settings:
            if !settingsPath.isEmpty { settingsPath.removeLast() }
        }
    }

    func popToRoot() {
        switch selectedTab {
        case .dashboard:
            dashboardPath = NavigationPath()
        case .journey:
            journeyPath = NavigationPath()
        case .gallery:
            galleryPath = NavigationPath()
        case .settings:
            settingsPath = NavigationPath()
        }
    }
}
