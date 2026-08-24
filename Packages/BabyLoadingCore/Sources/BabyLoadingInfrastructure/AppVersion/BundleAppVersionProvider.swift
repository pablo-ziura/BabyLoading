import Foundation

public struct BundleAppVersionProvider: AppVersionProviderProtocol, Sendable {
    private let bundle: Bundle

    public init(bundle: Bundle) {
        self.bundle = bundle
    }

    public func marketingVersion() -> String {
        bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }
}
