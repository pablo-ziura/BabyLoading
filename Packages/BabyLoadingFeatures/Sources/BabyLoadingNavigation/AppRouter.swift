import Observation

public enum AppTab: String, CaseIterable, Hashable, Identifiable, Sendable {
    case dashboard
    case journey
    case gallery
    case settings

    public var id: String {
        rawValue
    }

    public var titleKey: String {
        "tabs.\(rawValue)"
    }

    public var systemImage: String {
        switch self {
        case .dashboard:
            "heart.fill"
        case .journey:
            "map.fill"
        case .gallery:
            "photo.on.rectangle.fill"
        case .settings:
            "gearshape.fill"
        }
    }
}

public enum AppFullScreenDestination: Hashable, Identifiable, Sendable {
    case bellyTrackingCamera

    public var id: Self {
        self
    }
}

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
