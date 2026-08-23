import SwiftUI

@main
struct BabyLoadingApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var coordinator = Coordinator()

    var body: some Scene {
        WindowGroup {
            coordinator.makeMainTabView()
                .preferredColorScheme(.light)
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    coordinator.viewModel.reloadContentForCurrentLanguage()
                }
        }
    }
}
