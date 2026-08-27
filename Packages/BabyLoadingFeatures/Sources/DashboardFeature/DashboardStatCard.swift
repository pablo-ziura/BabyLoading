import BabyLoadingDesignComponents
import BabyLoadingDesignTokens
import SwiftUI

struct DashboardStatCard: View {
    private static let metricLabelMinHeight = BabyLoadingSpacing.extraLarge + BabyLoadingSpacing.medium

    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(spacing: BabyLoadingSpacing.small) {
            Image(systemName: systemImage)
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
                .frame(minHeight: BabyLoadingSpacing.extraLarge)

            Text(title)
                .font(BabyLoadingTypography.text(.caption))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(
                    maxWidth: .infinity,
                    minHeight: Self.metricLabelMinHeight,
                    alignment: .top
                )
        }
        .frame(maxWidth: .infinity, minHeight: 112)
        .softCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(value))
    }
}
