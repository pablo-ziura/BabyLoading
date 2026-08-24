import SwiftUI

public struct BabyLoadingShadowStyle: Sendable {
    public let color: Color
    public let radius: CGFloat
    public let horizontalOffset: CGFloat
    public let verticalOffset: CGFloat

    public nonisolated init(
        color: Color,
        radius: CGFloat,
        horizontalOffset: CGFloat = 0,
        verticalOffset: CGFloat
    ) {
        self.color = color
        self.radius = radius
        self.horizontalOffset = horizontalOffset
        self.verticalOffset = verticalOffset
    }
}

public enum BabyLoadingElevation {
    public nonisolated static var softCard: BabyLoadingShadowStyle {
        BabyLoadingShadowStyle(
            color: .black.opacity(0.08),
            radius: 12,
            verticalOffset: 6
        )
    }

    public nonisolated static var selectedTimelineCard: BabyLoadingShadowStyle {
        BabyLoadingShadowStyle(
            color: .pink.opacity(0.15),
            radius: 8,
            verticalOffset: 4
        )
    }
}
