import Foundation

public protocol AppVersionProviderProtocol: Sendable {
    func marketingVersion() -> String
}

public struct BundleAppVersionProvider: AppVersionProviderProtocol, Sendable {
    private let bundle: Bundle

    public init(bundle: Bundle) {
        self.bundle = bundle
    }

    public func marketingVersion() -> String {
        bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }
}

public protocol LoadAppVersionUseCaseProtocol: Sendable {
    func execute() -> String
}

public struct LoadAppVersionUseCase: LoadAppVersionUseCaseProtocol, Sendable {
    private let provider: any AppVersionProviderProtocol

    public init(provider: any AppVersionProviderProtocol) {
        self.provider = provider
    }

    public func execute() -> String {
        provider.marketingVersion()
    }
}
