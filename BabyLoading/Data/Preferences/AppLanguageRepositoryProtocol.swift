import Foundation

protocol AppLanguageRepositoryProtocol {
    var availableLanguages: [AppLanguage] { get }

    func selectedLanguage() -> AppLanguage
    func updateSelectedLanguage(_ language: AppLanguage)
}
