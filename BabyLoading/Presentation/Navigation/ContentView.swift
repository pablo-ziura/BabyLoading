import BabyLoadingDesignTokens
import BabyLoadingNavigation
import DashboardFeature
import GalleryFeature
import JourneyFeature
import SettingsFeature
import SwiftUI

struct MainTabView: View {
    @Environment(AppRouter.self) private var router
    @Environment(GalleryViewModel.self) private var galleryViewModel

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
                    referenceImageData: galleryViewModel.lastBellyTrackingImageData,
                    onPhotoCaptured: { capturedData in
                        await galleryViewModel.saveCapturedBellyTrackingPhoto(capturedData)
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
    @Previewable @State var coordinator = Coordinator()
    coordinator.makeMainTabView()
}
