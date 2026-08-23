import SwiftUI

@main
@MainActor
struct BabyLoadingApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var coordinator = Coordinator()

    var body: some Scene {
        WindowGroup {
            coordinator.makeMainTabView()
                .preferredColorScheme(.light)
                .task {
                    await coordinator.start()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    Task {
                        await coordinator.reloadLocalizedFeaturesIfNeeded()
                    }
                }
        }
    }
}
