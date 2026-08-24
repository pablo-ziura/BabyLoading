import SwiftUI

extension Coordinator {
    func makeMainTabView() -> some View {
        MainTabView()
            .environment(router)
            .environment(dashboardViewModel)
            .environment(journeyViewModel)
            .environment(galleryViewModel)
            .environment(settingsViewModel)
    }
}
