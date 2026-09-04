import SwiftUI

@main
@MainActor
struct BabyLoadingApp: App {
    @UIApplicationDelegateAdaptor(FirebaseApplicationDelegate.self)
    private var firebaseApplicationDelegate

    @Environment(\.scenePhase) private var scenePhase
    @State private var coordinator = Coordinator()

    var body: some Scene {
        BabyLoadingScene(
            coordinator: coordinator,
            scenePhase: scenePhase
        )
    }
}
