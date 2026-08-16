import SwiftUI

enum BabyLoadingTypography {
    enum Weight {
        case regular
        case medium
        case semibold
        case bold
        case extraBold
    }

    nonisolated static func text(
        _ style: Font.TextStyle,
        weight: Weight = .regular,
        italic: Bool = false
    ) -> Font {
        Font.custom(
            fontName(for: weight, italic: italic),
            size: pointSize(for: style),
            relativeTo: style
        )
    }

    nonisolated static func widget(
        size: CGFloat,
        weight: Weight = .regular,
        italic: Bool = false
    ) -> Font {
        Font.custom(
            fontName(for: weight, italic: italic),
            fixedSize: size
        )
    }

    nonisolated private static func fontName(for weight: Weight, italic: Bool) -> String {
        switch (weight, italic) {
        case (.regular, false): "NunitoSans-12ptExtraLight_Regular"
        case (.medium, false): "NunitoSans-12ptExtraLight_Medium"
        case (.semibold, false): "NunitoSans-12ptExtraLight_SemiBold"
        case (.bold, false): "NunitoSans-12ptExtraLight_Bold"
        case (.extraBold, false): "NunitoSans-12ptExtraLight_ExtraBold"
        case (.regular, true): "NunitoSans-12ptExtraLightItalic_Italic"
        case (.medium, true): "NunitoSans-12ptExtraLightItalic_Medium-Italic"
        case (.semibold, true): "NunitoSans-12ptExtraLightItalic_SemiBold-Italic"
        case (.bold, true): "NunitoSans-12ptExtraLightItalic_Bold-Italic"
        case (.extraBold, true): "NunitoSans-12ptExtraLightItalic_ExtraBold-Italic"
        }
    }

    nonisolated private static func pointSize(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline, .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        @unknown default: 17
        }
    }
}
