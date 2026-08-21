import Foundation

final class AppLanguageRepository: AppLanguageRepositoryProtocol {
    private let bundlePreferredLocalizations: () -> [String]
    private let preferredLanguages: () -> [String]

    init(
        bundlePreferredLocalizations: @escaping () -> [String] = { Bundle.main.preferredLocalizations },
        preferredLanguages: @escaping () -> [String] = { Locale.preferredLanguages }
    ) {
        self.bundlePreferredLocalizations = bundlePreferredLocalizations
        self.preferredLanguages = preferredLanguages
    }

    func resolvedLanguage() -> AppLanguage {
        AppLanguage.resolve(
            preferredLanguages: bundlePreferredLocalizations() + preferredLanguages()
        )
    }
}
