import Foundation

public protocol ResolveAppLanguageUseCaseProtocol: Sendable {
    func execute(preferredLanguages: [String]) -> AppLanguage
}
