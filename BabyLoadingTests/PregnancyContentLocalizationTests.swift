@testable import BabyLoading
import XCTest

final class PregnancyContentLocalizationTests: XCTestCase {
    func testResolvedLocale_usesSupportedPreferredLanguage() {
        let localization = PregnancyContentLocalization(
            bundle: .main,
            preferredLanguages: ["es-ES"],
            bundlePreferredLocalizations: [],
            supportedLocales: ["en", "es"]
        )

        XCTAssertEqual(localization.localeCode, "es")
        XCTAssertEqual(localization.resourceName, "pregnancy-content.es")
        XCTAssertEqual(localization.fileName, "pregnancy-content.es.json")
    }

    func testResolvedLocale_fallsBackToEnglishWhenPreferredLanguageIsUnsupported() {
        let localization = PregnancyContentLocalization(
            bundle: .main,
            preferredLanguages: ["fr-FR"],
            bundlePreferredLocalizations: [],
            supportedLocales: ["en", "es"]
        )

        XCTAssertEqual(localization.localeCode, "en")
    }

    func testResolvedLocale_prefersBundleLocalizationOverride() {
        let localization = PregnancyContentLocalization(
            bundle: .main,
            preferredLanguages: ["fr-FR"],
            bundlePreferredLocalizations: ["es"],
            supportedLocales: ["en", "es"]
        )

        XCTAssertEqual(localization.localeCode, "es")
    }
}
