@testable import BabyLoading
import Testing

struct AppLanguageRepositoryTests {
    @Test func resolvedLanguagePrioritizesAppLanguageOverDeviceLanguage() {
        let repository = AppLanguageRepository(
            bundlePreferredLocalizations: { ["en"] },
            preferredLanguages: { ["es-ES"] }
        )

        #expect(repository.resolvedLanguage() == .english)
    }

    @Test func resolvedLanguageUsesSupportedDeviceLanguageWhenAppLanguageIsMissing() {
        let repository = AppLanguageRepository(
            bundlePreferredLocalizations: { [] },
            preferredLanguages: { ["es-ES"] }
        )

        #expect(repository.resolvedLanguage() == .spanish)
    }

    @Test func resolvedLanguageFallsBackToEnglishWhenNoSupportedLanguageExists() {
        let repository = AppLanguageRepository(
            bundlePreferredLocalizations: { ["fr"] },
            preferredLanguages: { ["de-DE"] }
        )

        #expect(repository.resolvedLanguage() == .english)
    }
}
