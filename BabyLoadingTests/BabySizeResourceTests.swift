@testable import BabyLoading
import Foundation
import Testing
import UIKit

struct BabySizeResourceTests {
    @Test func babySizeImageNames_existInAssetCatalog() throws {
        let expected = BabySize.allCases.filter { $0 != .unknown }.map(\.imageName)
        let missingAssets = expected.filter { imageName in
            UIImage(
                named: imageName,
                in: Bundle(for: BundleMarker.self),
                compatibleWith: nil
            ) == nil
        }

        #expect(
            missingAssets.isEmpty,
            """
            Faltan recursos para BabySize en Assets.xcassets/Images:
            \(missingAssets.joined(separator: ", "))
            """
        )
    }
}

private final class BundleMarker {}
