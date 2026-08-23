@testable import BabyLoading
import Testing

struct LegacyContentCacheContractTests {
    @Test func cacheDocumentsRemainSeparatedByLocale() {
        let englishLocalization = PregnancyContentLocalization(localeCode: "en")
        let spanishLocalization = PregnancyContentLocalization(localeCode: "es")

        #expect(englishLocalization.fileName == "pregnancy-content.en.json")
        #expect(spanishLocalization.fileName == "pregnancy-content.es.json")
        #expect(englishLocalization.fileName != spanishLocalization.fileName)
    }
}
