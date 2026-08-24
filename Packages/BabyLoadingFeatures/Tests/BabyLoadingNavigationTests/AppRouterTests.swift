import BabyLoadingNavigation
import Testing

@MainActor
struct AppRouterTests {
    @Test
    func presentsAndDismissesBellyTrackingCamera() {
        let router = AppRouter()

        router.present(.bellyTrackingCamera)
        #expect(router.presentedFullScreenDestination == .bellyTrackingCamera)

        router.dismissFullScreenDestination()
        #expect(router.presentedFullScreenDestination == nil)
    }

    @Test
    func exposesOnlyCanonicalTabs() {
        #expect(AppTab.allCases == [.dashboard, .journey, .gallery, .settings])
    }
}
