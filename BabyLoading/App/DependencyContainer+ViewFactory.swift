import SwiftUI

extension Coordinator {
    func makeMainTabView() -> some View {
        MainTabView()
            .environment(router)
            .environment(viewModel)
            .environment(settingsViewModel)
    }
}
