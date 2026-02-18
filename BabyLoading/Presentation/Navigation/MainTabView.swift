import SwiftUI

struct MainTabView: View {
    @State private var viewModel = BabyProgressViewModel()
    @State private var selectedTab: TabItem = .dashboard

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            GradientBackground()

            // Tab Content
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView(viewModel: viewModel)
                case .journey:
                    JourneyView(viewModel: viewModel)
                case .gallery:
                    GalleryView(viewModel: viewModel)
                case .settings:
                    SettingsView(viewModel: viewModel)
                }
            }
            .transition(.opacity.animation(.easeInOut(duration: 0.15)))

            // Floating Pill Tab Bar
            VStack {
                Spacer()
                PillTabBar(selectedTab: $selectedTab)
                    .padding(.bottom, 8)
            }
        }
    }
}

#Preview {
    MainTabView()
}
