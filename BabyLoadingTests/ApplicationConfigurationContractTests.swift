@testable import BabyLoading
import XCTest

final class ApplicationConfigurationContractTests: XCTestCase {
    func testProcessedInfoPlistDisablesMultipleScenes() throws {
        let sceneManifest = try XCTUnwrap(
            Bundle.main.object(forInfoDictionaryKey: "UIApplicationSceneManifest") as? [String: Any]
        )

        XCTAssertEqual(sceneManifest["UIApplicationSupportsMultipleScenes"] as? Bool, false)
    }
}
