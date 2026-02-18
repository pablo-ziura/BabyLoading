import SwiftUI

@main
struct BabyLoadingApp: App {
    var body: some Scene {
        WindowGroup {
            DependencyContainer.shared.makeMainTabView()
                .preferredColorScheme(.light)
        }
    }
}
