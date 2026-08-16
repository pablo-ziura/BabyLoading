import Foundation
import SwiftUI

struct WeekRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let content: WeekContent
    let isCurrent: Bool
    let currentWeek: Int?
    let currentDayOffset: Int

    private var highlightedTopDay: Int? {
        guard let currentWeek, currentWeek + 1 == content.week, (4 ... 6).contains(currentDayOffset) else {
            return nil
        }
        return currentDayOffset - 4
    }

    private var highlightedBottomDay: Int? {
        guard currentWeek == content.week, (0 ... 3).contains(currentDayOffset) else {
            return nil
        }
        return currentDayOffset
    }

    var body: some View {
        HStack(spacing: 16) {
            timeline

            rowCard
        }
    }

    private var timeline: some View {
        VStack(spacing: 0) {
            TimelineDaySegment(
                dayCount: 3,
                highlightedDayIndex: highlightedTopDay
            )

            Circle()
                .fill(isCurrent ? .pink : .white.opacity(0.5))
                .frame(width: isCurrent ? 14 : 8, height: isCurrent ? 14 : 8)
                .overlay {
                    if isCurrent {
                        Circle()
                            .strokeBorder(.white, lineWidth: 2)
                    }
                }

            TimelineDaySegment(
                dayCount: 4,
                highlightedDayIndex: highlightedBottomDay
            )
        }
        .frame(width: 16)
        .accessibilityHidden(true)
    }

    private var rowCard: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 12) {
                    rowMainContent

                    if isCurrent {
                        currentWeekBadge
                    }
                }
            } else {
                HStack(spacing: 12) {
                    rowMainContent

                    Spacer(minLength: 12)

                    if isCurrent {
                        currentWeekBadge
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isCurrent ? .white : .white.opacity(0.88))
        )
        .shadow(color: isCurrent ? .pink.opacity(0.15) : .clear, radius: 8, y: 4)
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityValue(isCurrent ? Text("journey.youAreHere") : Text(verbatim: ""))
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    private var rowMainContent: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 40, height: 40)

                Image(content.babySize.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                Circle()
                    .strokeBorder(.pink.opacity(0.2), lineWidth: 1.5)
                    .frame(width: 40, height: 40)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(
                    String(
                        format: String(localized: "common.week", defaultValue: "Week %d"),
                        locale: .current,
                        content.week
                    )
                )
                    .font(
                        BabyLoadingTypography.text(
                            .headline,
                            weight: isCurrent ? .bold : .medium
                        )
                    )

                Text(content.babySizeLabel.localizedCapitalized)
                    .font(BabyLoadingTypography.text(.caption))
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(
                        Text(
                            String(
                                format: String(
                                    localized: "dashboard.babySize",
                                    defaultValue: "Your baby is now the size of %@"
                                ),
                                locale: .current,
                                content.babySizeLabel
                            )
                        )
                    )
            }
        }
    }

    private var currentWeekBadge: some View {
        Text("journey.youAreHere")
            .font(BabyLoadingTypography.text(.caption2, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.pink, .purple.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .accessibilityHidden(true)
    }
}

private struct TimelineDaySegment: View {
    let dayCount: Int
    let highlightedDayIndex: Int?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Rectangle()
                    .fill(.white.opacity(0.3))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)

                ForEach(0 ..< dayCount, id: \.self) { index in
                    let isHighlighted = index == highlightedDayIndex
                    let yPosition = proxy.size.height * (CGFloat(index + 1) / 4)

                    Circle()
                        .fill(isHighlighted ? .pink : .white.opacity(0.65))
                        .frame(width: isHighlighted ? 7 : 4, height: isHighlighted ? 7 : 4)
                        .overlay {
                            if isHighlighted {
                                Circle()
                                    .strokeBorder(.white, lineWidth: 1)
                            }
                        }
                        .position(x: proxy.size.width / 2, y: yPosition)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
}
