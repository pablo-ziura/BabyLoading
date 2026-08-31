@testable import BabyLoading
import XCTest

final class PrivacyManifestContractTests: XCTestCase {
    func testAppManifestDeclaresRequiredReasonAPIs() throws {
        let manifestURL = try XCTUnwrap(
            Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy")
        )
        let manifest = try loadManifest(at: manifestURL)

        XCTAssertEqual(manifest["NSPrivacyTracking"] as? Bool, false)
        XCTAssertTrue((manifest["NSPrivacyCollectedDataTypes"] as? [Any])?.isEmpty == true)
        XCTAssertEqual(manifest["NSPrivacyTrackingDomains"] as? [String], [])
        XCTAssertEqual(
            accessedAPIReasons(in: manifest),
            [
                "NSPrivacyAccessedAPICategoryFileTimestamp": ["C617.1"],
                "NSPrivacyAccessedAPICategoryUserDefaults": ["1C8F.1"]
            ]
        )
    }

    func testWidgetManifestDeclaresSharedDefaultsReason() throws {
        let manifestURL = try widgetManifestURL()
        let manifest = try loadManifest(at: manifestURL)

        XCTAssertEqual(manifest["NSPrivacyTracking"] as? Bool, false)
        XCTAssertTrue((manifest["NSPrivacyCollectedDataTypes"] as? [Any])?.isEmpty == true)
        XCTAssertEqual(manifest["NSPrivacyTrackingDomains"] as? [String], [])
        XCTAssertEqual(
            accessedAPIReasons(in: manifest),
            ["NSPrivacyAccessedAPICategoryUserDefaults": ["1C8F.1"]]
        )
    }

    func testBuiltProductsContainTargetSpecificManifests() throws {
        XCTAssertNotNil(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))

        let widgetURL = try widgetManifestURL()
        XCTAssertTrue(FileManager.default.fileExists(atPath: widgetURL.path))
    }

    private func widgetManifestURL() throws -> URL {
        try XCTUnwrap(Bundle.main.builtInPlugInsURL?
            .appendingPathComponent("BabyProgressWidgetExtension.appex")
            .appendingPathComponent("PrivacyInfo.xcprivacy"))
    }

    private func loadManifest(at url: URL) throws -> [String: Any] {
        let data = try Data(contentsOf: url)
        return try XCTUnwrap(
            PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )
    }

    private func accessedAPIReasons(in manifest: [String: Any]) -> [String: [String]] {
        let entries = manifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]] ?? []
        return Dictionary(uniqueKeysWithValues: entries.compactMap { entry in
            guard let category = entry["NSPrivacyAccessedAPIType"] as? String,
                  let reasons = entry["NSPrivacyAccessedAPITypeReasons"] as? [String] else {
                return nil
            }
            return (category, reasons)
        })
    }
}
