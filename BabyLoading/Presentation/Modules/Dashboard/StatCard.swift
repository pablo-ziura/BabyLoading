import BabyLoadingDesignComponents
import BabyLoadingDesignTokens
import Foundation
import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            BabyLoadingColors.selectionAccent,
                            BabyLoadingColors.selectionGradientEnd
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .accessibilityHidden(true)

            Text(value)
                .font(BabyLoadingTypography.text(.title, weight: .bold))
                .foregroundStyle(.primary)

            Text(title)
                .font(BabyLoadingTypography.text(.caption))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .softCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(value))
    }
}
