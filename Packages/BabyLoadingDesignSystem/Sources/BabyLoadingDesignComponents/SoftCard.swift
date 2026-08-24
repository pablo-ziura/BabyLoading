import BabyLoadingDesignTokens
import SwiftUI

public struct SoftCard: ViewModifier {
    private let cornerRadius: CGFloat

    public init(cornerRadius: CGFloat = BabyLoadingShape.softCardCornerRadius) {
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        let shadow = BabyLoadingElevation.softCard

        content
            .padding(BabyLoadingSpacing.medium)
            .background(BabyLoadingColors.primaryCardSurface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.horizontalOffset,
                y: shadow.verticalOffset
            )
    }
}

public extension View {
    func softCard(cornerRadius: CGFloat = BabyLoadingShape.softCardCornerRadius) -> some View {
        modifier(SoftCard(cornerRadius: cornerRadius))
    }
}
