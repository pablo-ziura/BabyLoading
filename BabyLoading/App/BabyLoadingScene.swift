import SwiftUI

@MainActor
struct BabyLoadingScene: Scene {
    let coordinator: Coordinator
    let scenePhase: ScenePhase

    var body: some Scene {
        WindowGroup {
            coordinator.makeMainTabView()
                .preferredColorScheme(.light)
                .task {
                    await coordinator.start()
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task {
                await coordinator.applicationDidBecomeActive()
            }
        }
    }
}
