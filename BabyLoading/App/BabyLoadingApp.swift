import SwiftUI

@main
struct BabyLoadingApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            DependencyContainer.shared.makeMainTabView()
                .preferredColorScheme(.light)
                .task {
                    await DependencyContainer.shared.viewModel.refreshContentIfNeeded()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    Task {
                        await DependencyContainer.shared.viewModel.refreshContentIfNeeded()
                    }
                }
        }
    }
}
