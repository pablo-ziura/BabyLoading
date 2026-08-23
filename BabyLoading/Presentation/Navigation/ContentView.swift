import BabyLoadingNavigation
import SwiftUI

struct MainTabView: View {
    @Bindable var router: AppRouter
    let coordinator: Coordinator

    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack {
                coordinator.makeDashboardView()
            }
            .tabItem {
                tabLabel(for: .dashboard)
            }
            .tag(AppTab.dashboard)

            NavigationStack {
                coordinator.makeJourneyView()
            }
            .tabItem {
                tabLabel(for: .journey)
            }
            .tag(AppTab.journey)

            NavigationStack {
                coordinator.makeGalleryView()
            }
            .tabItem {
                tabLabel(for: .gallery)
            }
            .tag(AppTab.gallery)

            NavigationStack {
                coordinator.makeSettingsView()
            }
            .tabItem {
                tabLabel(for: .settings)
            }
            .tag(AppTab.settings)
        }
        .tint(.pink)
    }

    private func tabLabel(for tab: AppTab) -> some View {
        Label(LocalizedStringKey(tab.titleKey), systemImage: tab.systemImage)
    }
}

#Preview {
    let coordinator = Coordinator()
    MainTabView(
        router: coordinator.router,
        coordinator: coordinator
    )
}
