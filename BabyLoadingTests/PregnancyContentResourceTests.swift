@testable import BabyLoading
import XCTest

final class PregnancyContentResourceTests: XCTestCase {
    func testBundledPregnancyContent_isPresentAndValidForSupportedLocales() throws {
        let bundle = Bundle(for: BundleMarker.self)
        for locale in ["en", "es"] {
            let url = try XCTUnwrap(bundle.url(forResource: "pregnancy-content.\(locale)", withExtension: "json"))
            let data = try Data(contentsOf: url)

            let document = try PregnancyContentDocument.decodeValidated(from: data, expectedLocale: locale)

            XCTAssertEqual(document.locale, locale)
            XCTAssertEqual(document.weeks.map(\.week), PregnancyContentDocument.coveredWeeks)
        }
    }
}

private final class BundleMarker {}
