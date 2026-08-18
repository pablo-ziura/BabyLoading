import Foundation

nonisolated enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case english = "en"
    case spanish = "es"

    var id: String { rawValue }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    var nativeName: String {
        switch self {
        case .english:
            "English"
        case .spanish:
            "Español"
        }
    }

    static func resolve(preferredLanguages: [String]) -> AppLanguage {
        let supportedLanguageCodes = allCases.map(\.rawValue)
        let preferredLanguage = Bundle.preferredLocalizations(
            from: supportedLanguageCodes,
            forPreferences: preferredLanguages
        ).first

        return preferredLanguage.flatMap(AppLanguage.init(rawValue:)) ?? .english
    }
}
