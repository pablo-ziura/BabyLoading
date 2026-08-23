@testable import BabyLoading
import Testing
import UIKit

struct BabyLoadingTypographyTests {
    @Test func nunitoSansFaces_areRegisteredInTheHostApp() {
        let requiredPostScriptNames = [
            "NunitoSans-12ptExtraLight_Regular",
            "NunitoSans-12ptExtraLight_Medium",
            "NunitoSans-12ptExtraLight_SemiBold",
            "NunitoSans-12ptExtraLight_Bold",
            "NunitoSans-12ptExtraLight_ExtraBold",
            "NunitoSans-12ptExtraLightItalic_Italic",
            "NunitoSans-12ptExtraLightItalic_Medium-Italic",
            "NunitoSans-12ptExtraLightItalic_SemiBold-Italic",
            "NunitoSans-12ptExtraLightItalic_Bold-Italic",
            "NunitoSans-12ptExtraLightItalic_ExtraBold-Italic"
        ]

        let missingFaces = requiredPostScriptNames.filter { name in
            UIFont(name: name, size: 17) == nil
        }
        let registeredNunitoFaces = UIFont.familyNames
            .filter { $0.localizedCaseInsensitiveContains("nunito") }
            .flatMap(UIFont.fontNames(forFamilyName:))
        let missingFaceNames = missingFaces.joined(separator: ", ")
        let registeredFaceNames = registeredNunitoFaces.joined(separator: ", ")

        #expect(
            missingFaces.isEmpty,
            "Missing Nunito Sans faces: \(missingFaceNames). Registered: \(registeredFaceNames)"
        )
    }
}
