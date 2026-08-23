import BabyLoadingDesignTokens
import BabyLoadingNavigation
import JourneyFeature
import SettingsFeature
import SwiftUI

struct MainTabView: View {
    @Environment(AppRouter.self) private var router
    @Environment(BabyProgressViewModel.self) private var viewModel

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                tabLabel(for: .dashboard)
            }
            .tag(AppTab.dashboard)

            NavigationStack {
                JourneyView()
            }
            .tabItem {
                tabLabel(for: .journey)
            }
            .tag(AppTab.journey)

            NavigationStack {
                GalleryView()
            }
            .tabItem {
                tabLabel(for: .gallery)
            }
            .tag(AppTab.gallery)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                tabLabel(for: .settings)
            }
            .tag(AppTab.settings)
        }
        .tint(BabyLoadingColors.selectionAccent)
        .fullScreenCover(item: presentedFullScreenDestination) { destination in
            switch destination {
            case .bellyTrackingCamera:
                BellyTrackingCameraView(
                    referenceImageData: viewModel.lastBellyTrackingImageData,
                    onPhotoCaptured: { capturedData in
                        await viewModel.saveBellyTrackingPhoto(capturedData)
                    }
                )
            }
        }
    }

    private func tabLabel(for tab: AppTab) -> some View {
        Label(LocalizedStringKey(tab.titleKey), systemImage: tab.systemImage)
    }

    private var presentedFullScreenDestination: Binding<AppFullScreenDestination?> {
        Binding(
            get: { router.presentedFullScreenDestination },
            set: { destination in
                if let destination {
                    router.present(destination)
                } else {
                    router.dismissFullScreenDestination()
                }
            }
        )
    }
}

#Preview {
    Coordinator().makeMainTabView()
}
