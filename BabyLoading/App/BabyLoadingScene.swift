import SwiftUI

@MainActor
struct BabyLoadingScene: Scene {
    let coordinator: Coordinator
    let scenePhase: ScenePhase

    var body: some Scene {
        WindowGroup {
            coordinator.makeMainTabView()
                .preferredColorScheme(.light)
                .onOpenURL { coordinator.handleOpenURL($0) }
                .task {
                    await coordinator.start()
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            Task {
                if newPhase == .active {
                    await coordinator.applicationDidBecomeActive()
                } else {
                    await coordinator.applicationDidResignActive()
                }
            }
        }
    }
}
