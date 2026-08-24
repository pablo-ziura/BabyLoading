import SwiftUI

@main
@MainActor
struct BabyLoadingApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var coordinator = Coordinator()

    var body: some Scene {
        BabyLoadingScene(
            coordinator: coordinator,
            scenePhase: scenePhase
        )
    }
}
