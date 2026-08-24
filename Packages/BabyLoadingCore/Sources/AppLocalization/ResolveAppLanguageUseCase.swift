import Foundation

public struct ResolveAppLanguageUseCase: ResolveAppLanguageUseCaseProtocol, Sendable {
    public init() {}

    public func execute(preferredLanguages: [String]) -> AppLanguage {
        AppLanguage.resolve(preferredLanguages: preferredLanguages)
    }
}
