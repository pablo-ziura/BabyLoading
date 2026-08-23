import BabyLoadingNavigation
import SwiftUI

struct MainTabView: View {
    @Bindable var router: AppRouter
    let container: DependencyContainer

    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack {
                container.makeDashboardView()
            }
            .tabItem {
                tabLabel(for: .dashboard)
            }
            .tag(AppTab.dashboard)

            NavigationStack {
                container.makeJourneyView()
            }
            .tabItem {
                tabLabel(for: .journey)
            }
            .tag(AppTab.journey)

            NavigationStack {
                container.makeGalleryView()
            }
            .tabItem {
                tabLabel(for: .gallery)
            }
            .tag(AppTab.gallery)

            NavigationStack {
                container.makeSettingsView()
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
    MainTabView(
        router: DependencyContainer.shared.router,
        container: DependencyContainer.shared
    )
}
