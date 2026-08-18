import AppPreferences
import Foundation

final class AppLanguageRepository: AppLanguageRepositoryProtocol {
    private static let selectedLanguageKey = PreferenceKey<String>("selectedLanguage")

    private let preferencesStore: (any PreferencesStoreProtocol)?
    private let preferredLanguages: () -> [String]

    let availableLanguages = AppLanguage.allCases

    init(
        preferencesStore: (any PreferencesStoreProtocol)? = SharedAppGroup.preferencesStore(),
        preferredLanguages: @escaping () -> [String] = { Locale.preferredLanguages }
    ) {
        self.preferencesStore = preferencesStore
        self.preferredLanguages = preferredLanguages
    }

    func selectedLanguage() -> AppLanguage {
        guard let storedLanguageCode = try? preferencesStore?.read(Self.selectedLanguageKey),
              let language = AppLanguage(rawValue: storedLanguageCode)
        else {
            return AppLanguage.resolve(preferredLanguages: preferredLanguages())
        }

        return language
    }

    func updateSelectedLanguage(_ language: AppLanguage) {
        try? preferencesStore?.write(language.rawValue, for: Self.selectedLanguageKey)
    }
}
