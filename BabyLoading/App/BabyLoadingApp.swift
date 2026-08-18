import SwiftUI

@main
struct BabyLoadingApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        let viewModel = DependencyContainer.shared.viewModel

        WindowGroup {
            DependencyContainer.shared.makeMainTabView()
                .preferredColorScheme(.light)
                .environment(\.locale, viewModel.selectedLanguage.locale)
                .task(id: viewModel.selectedLanguage) {
                    await viewModel.refreshContentIfNeeded()
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
