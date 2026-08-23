import Foundation

public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case english = "en"
    case spanish = "es"

    public var id: String { rawValue }

    public var locale: Locale {
        Locale(identifier: rawValue)
    }

    public var nativeName: String {
        switch self {
        case .english:
            "English"
        case .spanish:
            "Español"
        }
    }

    public static func resolve(preferredLanguages: [String]) -> AppLanguage {
        let supportedLanguageCodes = allCases.map(\.rawValue)
        let preferredLanguage = Bundle.preferredLocalizations(
            from: supportedLanguageCodes,
            forPreferences: preferredLanguages
        ).first

        return preferredLanguage.flatMap(AppLanguage.init(rawValue:)) ?? .english
    }
}

public protocol ResolveAppLanguageUseCaseProtocol: Sendable {
    func execute(preferredLanguages: [String]) -> AppLanguage
}

public struct ResolveAppLanguageUseCase: ResolveAppLanguageUseCaseProtocol, Sendable {
    public init() {}

    public func execute(preferredLanguages: [String]) -> AppLanguage {
        AppLanguage.resolve(preferredLanguages: preferredLanguages)
    }
}
