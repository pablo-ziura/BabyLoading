@testable import BabyLoading

final class MockAppLanguageRepository: AppLanguageRepositoryProtocol {
    var systemLanguage: AppLanguage = .english

    func resolvedLanguage() -> AppLanguage {
        systemLanguage
    }
}
