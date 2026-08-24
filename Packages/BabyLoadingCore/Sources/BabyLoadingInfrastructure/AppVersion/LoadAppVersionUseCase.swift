import Foundation

public struct LoadAppVersionUseCase: LoadAppVersionUseCaseProtocol, Sendable {
    private let provider: any AppVersionProviderProtocol

    public init(provider: any AppVersionProviderProtocol) {
        self.provider = provider
    }

    public func execute() -> String {
        provider.marketingVersion()
    }
}
