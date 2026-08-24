import Foundation

public protocol AppVersionProviderProtocol: Sendable {
    func marketingVersion() -> String
}
