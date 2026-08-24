import SwiftUI

public enum BabyLoadingColors {
    public nonisolated static var backgroundGradientTop: Color {
        Color(red: 1.0, green: 0.75, blue: 0.82)
    }

    public nonisolated static var backgroundGradientBottom: Color {
        Color(red: 0.78, green: 0.72, blue: 0.96)
    }

    public nonisolated static var brandBerry: Color {
        Color(
            red: 155.0 / 255.0,
            green: 64.0 / 255.0,
            blue: 92.0 / 255.0
        )
    }

    public nonisolated static var selectionAccent: Color {
        .pink
    }

    public nonisolated static var selectionGradientEnd: Color {
        .purple.opacity(0.8)
    }

    public nonisolated static var primaryCardSurface: Color {
        .white
    }

    public nonisolated static var secondaryCardSurface: Color {
        .white.opacity(0.88)
    }

    public nonisolated static var primaryText: Color {
        .primary
    }

    public nonisolated static var secondaryText: Color {
        .secondary
    }

    public nonisolated static var timelineLine: Color {
        .white.opacity(0.3)
    }

    public nonisolated static var passiveTimelineMarker: Color {
        .white.opacity(0.5)
    }

    public nonisolated static var emphasizedTimelineMarker: Color {
        .white.opacity(0.65)
    }

    public nonisolated static var positiveStatusSurface: Color {
        .green.opacity(0.18)
    }

    public nonisolated static var attentionStatusSurface: Color {
        .orange.opacity(0.18)
    }
}
