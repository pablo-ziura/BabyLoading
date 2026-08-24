import AppLocalization
import Testing

struct AppLocalizationTests {
    @Test func resolvesSupportedRegionalLanguage() {
        let language = ResolveAppLanguageUseCase().execute(preferredLanguages: ["es-ES"])

        #expect(language == .spanish)
        #expect(language.rawValue == "es")
        #expect(language.nativeName == "Español")
    }

    @Test func unsupportedLanguageFallsBackToEnglish() {
        let language = ResolveAppLanguageUseCase().execute(preferredLanguages: ["fr-FR"])

        #expect(language == .english)
    }

    @Test func applicationLocalizationTakesPriorityOverDeviceLanguage() {
        let language = ResolveAppLanguageUseCase().execute(
            preferredLanguages: ["es", "en-US"]
        )

        #expect(language == .spanish)
    }
}
