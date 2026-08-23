import SwiftUI

@main
struct BabyLoadingApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        let viewModel = DependencyContainer.shared.viewModel

        WindowGroup {
            DependencyContainer.shared.makeMainTabView()
                .preferredColorScheme(.light)
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    viewModel.reloadContentForCurrentLanguage()
                }
        }
    }
}
