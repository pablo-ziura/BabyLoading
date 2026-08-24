import Foundation

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
