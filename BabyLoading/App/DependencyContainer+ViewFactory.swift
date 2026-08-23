import SwiftUI

extension Coordinator {
    // MARK: - Coordinator Factory

    func makeMainTabView() -> MainTabView {
        MainTabView(router: router, coordinator: self)
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
}
