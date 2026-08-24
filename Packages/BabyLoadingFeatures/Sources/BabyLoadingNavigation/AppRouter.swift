import Foundation

@MainActor
@Observable
public final class AppRouter {
    public var selectedTab: AppTab
    public private(set) var presentedFullScreenDestination: AppFullScreenDestination?

    public init(
        selectedTab: AppTab = .dashboard,
        presentedFullScreenDestination: AppFullScreenDestination? = nil
    ) {
        self.selectedTab = selectedTab
        self.presentedFullScreenDestination = presentedFullScreenDestination
    }

    public func present(_ destination: AppFullScreenDestination) {
        presentedFullScreenDestination = destination
    }

    public func dismissFullScreenDestination() {
        presentedFullScreenDestination = nil
    }
}
