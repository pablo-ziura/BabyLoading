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
        GalleryView(
            viewModel: viewModel,
            makeBellyTrackingCameraView: { referenceImageData, onPhotoCaptured in
                AnyView(
                    BellyTrackingCameraView(
                        referenceImageData: referenceImageData,
                        onPhotoCaptured: onPhotoCaptured
                    )
                )
            }
        )
    }

    func makeSettingsView() -> some View {
        SettingsView(viewModel: viewModel)
    }

    @ViewBuilder
    func view(for route: AppRoute, locale: Locale) -> some View {
        switch route {
        case let .detail(id):
            Text(
                String(
                    format: String(localized: "detail.title", defaultValue: "Detail %@", locale: locale),
                    locale: locale,
                    id
                )
            )
        case .settings:
            makeSettingsView()
        }
    }
}
