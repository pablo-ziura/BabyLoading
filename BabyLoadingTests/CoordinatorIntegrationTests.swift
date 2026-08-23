@testable import BabyLoading
import DashboardFeature
import GalleryFeature
import JourneyFeature
import SettingsFeature
import Testing

struct CoordinatorIntegrationTests {
    @Test @MainActor
    func startReloadsEveryFeatureViewModel() async {
        let coordinator = Coordinator()

        #expect(coordinator.dashboardViewModel.loadingState == .idle)
        #expect(coordinator.journeyViewModel.loadingState == .idle)
        #expect(coordinator.galleryViewModel.loadingState == .idle)
        #expect(coordinator.settingsViewModel.loadingState == .idle)

        await coordinator.start()

        #expect(coordinator.dashboardViewModel.loadingState != .idle)
        #expect(coordinator.journeyViewModel.loadingState != .idle)
        #expect(coordinator.galleryViewModel.loadingState != .idle)
        #expect(coordinator.settingsViewModel.loadingState != .idle)
    }
}
