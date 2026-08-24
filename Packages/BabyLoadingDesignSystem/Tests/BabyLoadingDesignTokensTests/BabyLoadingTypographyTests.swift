import SwiftUI
import Testing
@testable import BabyLoadingDesignTokens

struct BabyLoadingTypographyTests {
    @Test
    func regularFontNamesMatchBundledPostScriptNames() {
        #expect(
            BabyLoadingTypography.fontName(for: .regular, italic: false)
                == "NunitoSans-12ptExtraLight_Regular"
        )
        #expect(
            BabyLoadingTypography.fontName(for: .medium, italic: false)
                == "NunitoSans-12ptExtraLight_Medium"
        )
        #expect(
            BabyLoadingTypography.fontName(for: .semibold, italic: false)
                == "NunitoSans-12ptExtraLight_SemiBold"
        )
        #expect(
            BabyLoadingTypography.fontName(for: .bold, italic: false)
                == "NunitoSans-12ptExtraLight_Bold"
        )
        #expect(
            BabyLoadingTypography.fontName(for: .extraBold, italic: false)
                == "NunitoSans-12ptExtraLight_ExtraBold"
        )
    }

    @Test
    func italicFontNamesMatchBundledPostScriptNames() {
        #expect(
            BabyLoadingTypography.fontName(for: .regular, italic: true)
                == "NunitoSans-12ptExtraLightItalic_Italic"
        )
        #expect(
            BabyLoadingTypography.fontName(for: .medium, italic: true)
                == "NunitoSans-12ptExtraLightItalic_Medium-Italic"
        )
        #expect(
            BabyLoadingTypography.fontName(for: .semibold, italic: true)
                == "NunitoSans-12ptExtraLightItalic_SemiBold-Italic"
        )
        #expect(
            BabyLoadingTypography.fontName(for: .bold, italic: true)
                == "NunitoSans-12ptExtraLightItalic_Bold-Italic"
        )
        #expect(
            BabyLoadingTypography.fontName(for: .extraBold, italic: true)
                == "NunitoSans-12ptExtraLightItalic_ExtraBold-Italic"
        )
    }

    @Test
    func textStylesKeepCanonicalBasePointSizes() {
        #expect(BabyLoadingTypography.pointSize(for: .largeTitle) == 34)
        #expect(BabyLoadingTypography.pointSize(for: .title) == 28)
        #expect(BabyLoadingTypography.pointSize(for: .title2) == 22)
        #expect(BabyLoadingTypography.pointSize(for: .title3) == 20)
        #expect(BabyLoadingTypography.pointSize(for: .headline) == 17)
        #expect(BabyLoadingTypography.pointSize(for: .body) == 17)
        #expect(BabyLoadingTypography.pointSize(for: .callout) == 16)
        #expect(BabyLoadingTypography.pointSize(for: .subheadline) == 15)
        #expect(BabyLoadingTypography.pointSize(for: .footnote) == 13)
        #expect(BabyLoadingTypography.pointSize(for: .caption) == 12)
        #expect(BabyLoadingTypography.pointSize(for: .caption2) == 11)
    }
}
