import Foundation

public struct PreferenceKey<Value: Codable & Sendable>: Hashable, Sendable {
    public let name: String

    public init(_ name: String) {
        self.name = name
    }
}
