@testable import BabyLoading

final class MockAppLanguageRepository: AppLanguageRepositoryProtocol {
    var availableLanguages: [AppLanguage] = AppLanguage.allCases
    var storedLanguage: AppLanguage = .english
    var updateSelectedLanguageCalled = false

    func selectedLanguage() -> AppLanguage {
        storedLanguage
    }

    func updateSelectedLanguage(_ language: AppLanguage) {
        updateSelectedLanguageCalled = true
        storedLanguage = language
    }
}
