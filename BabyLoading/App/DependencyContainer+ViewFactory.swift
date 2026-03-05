import SwiftUI

extension DependencyContainer {
    // MARK: - Coordinator Factory

    func makeMainTabView() -> MainTabView {
        MainTabView(coordinator: coordinator, container: self)
    }

    // MARK: - View Factories

    func makeDashboardView() -> some View {
        DashboardView(viewModel: viewModel)
    }

    func makeJourneyView() -> some View {
        JourneyView(viewModel: viewModel)
    }

    func makeGalleryView() -> some View {
        GalleryView(viewModel: viewModel)
    }

    func makeSettingsView() -> some View {
        SettingsView(viewModel: viewModel)
    }

    @ViewBuilder
    func view(for route: AppRoute) -> some View {
        switch route {
        case let .detail(id):
            Text("Detail \(id)")
        case .settings:
            makeSettingsView()
        }
    }
}
