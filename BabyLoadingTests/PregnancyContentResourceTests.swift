@testable import BabyLoading
import XCTest

final class PregnancyContentResourceTests: XCTestCase {
    func testBundledPregnancyContent_isPresentAndValid() throws {
        let bundle = Bundle(for: BundleMarker.self)
        let url = try XCTUnwrap(bundle.url(forResource: "pregnancy-content.es", withExtension: "json"))
        let data = try Data(contentsOf: url)

        let document = try PregnancyContentDocument.decodeValidated(from: data)

        XCTAssertEqual(document.weeks.map(\.week), PregnancyContentDocument.coveredWeeks)
    }
}

private final class BundleMarker {}
