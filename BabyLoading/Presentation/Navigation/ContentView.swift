import SwiftUI

struct MainTabView: View {
    @Bindable var coordinator: AppCoordinator
    let container: DependencyContainer

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            // MARK: - Dashboard Tab

            NavigationStack(path: $coordinator.dashboardPath) {
                container.makeDashboardView()
                    .navigationDestination(for: AppRoute.self) { route in
                        container.view(for: route)
                    }
            }
            .tabItem {
                Label(TabItem.dashboard.title, systemImage: TabItem.dashboard.icon)
            }
            .tag(TabItem.dashboard)

            // MARK: - Journey Tab

            NavigationStack(path: $coordinator.journeyPath) {
                container.makeJourneyView()
                    .navigationDestination(for: AppRoute.self) { route in
                        container.view(for: route)
                    }
            }
            .tabItem {
                Label(TabItem.journey.title, systemImage: TabItem.journey.icon)
            }
            .tag(TabItem.journey)

            // MARK: - Gallery Tab

            NavigationStack(path: $coordinator.galleryPath) {
                container.makeGalleryView()
                    .navigationDestination(for: AppRoute.self) { route in
                        container.view(for: route)
                    }
            }
            .tabItem {
                Label(TabItem.gallery.title, systemImage: TabItem.gallery.icon)
            }
            .tag(TabItem.gallery)

            // MARK: - Settings Tab

            NavigationStack(path: $coordinator.settingsPath) {
                container.makeSettingsView()
                    .navigationDestination(for: AppRoute.self) { route in
                        container.view(for: route)
                    }
            }
            .tabItem {
                Label(TabItem.settings.title, systemImage: TabItem.settings.icon)
            }
            .tag(TabItem.settings)
        }
        .tint(.pink)
    }
}

#Preview {
    MainTabView(
        coordinator: DependencyContainer.shared.coordinator,
        container: DependencyContainer.shared
    )
}
