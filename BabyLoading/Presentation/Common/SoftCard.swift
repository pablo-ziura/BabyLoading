import BabyLoadingDesignTokens
import SwiftUI

struct SoftCard: ViewModifier {
    var cornerRadius: CGFloat = BabyLoadingShape.softCardCornerRadius

    func body(content: Content) -> some View {
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

extension View {
    func softCard(
        cornerRadius: CGFloat = BabyLoadingShape.softCardCornerRadius
    ) -> some View {
        modifier(SoftCard(cornerRadius: cornerRadius))
    }
}
