import BabyLoadingDesignComponents
import BabyLoadingDesignTokens
import Foundation
import PregnancyContent
import PregnancyProgress
import SwiftUI

public struct JourneyView: View {
    @Environment(JourneyViewModel.self) private var viewModel
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.locale) private var locale
    @State private var hasAppeared = false
    @State private var isCurrentDayScrollPending = false
    @State private var currentDayScrollRequest: UUID?

    private let isSelected: Bool

    public init(isSelected: Bool) {
        self.isSelected = isSelected
    }

    public var body: some View {
        ZStack {
            GradientBackground()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        Text("journey.title")
                        .font(BabyLoadingTypography.text(.title2, weight: .bold))
                        .foregroundStyle(.primary)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h1)
                        .padding(.top, BabyLoadingSpacing.large)
                        .padding(.bottom, BabyLoadingSpacing.medium)

                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.pregnancyTimeline) { content in
                            let isCurrent = currentTimelineWeek == content.week

                            JourneyWeekRow(
                                content: content,
                                isCurrent: isCurrent,
                                currentWeek: currentTimelineWeek,
                                currentDayOffset: viewModel.currentDayOffset()
                            )
                            .id(content.week)
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 100)
                }
                }
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
                .onAppear {
                    guard !hasAppeared else { return }
                    hasAppeared = true
                    requestCurrentDayScroll()
                }
                .onChange(of: isSelected) { _, isSelected in
                    if isSelected {
                        requestCurrentDayScroll()
                    } else {
                        isCurrentDayScrollPending = false
                        currentDayScrollRequest = nil
                    }
                }
                .onChange(of: currentDayTimelineWeek) {
                    schedulePendingCurrentDayScroll()
                }
                .task(id: currentDayScrollRequest) { @MainActor in
                    guard let currentDayScrollRequest else { return }

                    await Task.yield()

                    guard !Task.isCancelled,
                          currentDayScrollRequest == self.currentDayScrollRequest,
                          let currentDayTimelineWeek else {
                        return
                    }

                    if accessibilityReduceMotion {
                        proxy.scrollTo(currentDayTimelineWeek, anchor: .center)
                    } else {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            proxy.scrollTo(currentDayTimelineWeek, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    private var activeProgress: ActivePregnancyProgress? {
        guard case let .some(.active(progress)) = viewModel.progress else {
            return nil
        }
        return progress
    }

    private var currentTimelineWeek: Int? {
        guard let activeProgress, activeProgress.phase == .ongoing else {
            return nil
        }
        return activeProgress.gestationalAge.weeks
    }

    private var currentDayTimelineWeek: Int? {
        viewModel.currentDayTimelineWeek()
    }

    private func requestCurrentDayScroll() {
        guard isSelected else { return }

        isCurrentDayScrollPending = true
        schedulePendingCurrentDayScroll()
    }

    private func schedulePendingCurrentDayScroll() {
        guard isCurrentDayScrollPending,
              currentDayTimelineWeek != nil else {
            return
        }

        isCurrentDayScrollPending = false
        currentDayScrollRequest = UUID()
    }
}

private struct JourneyWeekRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.locale) private var locale

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
        HStack(spacing: BabyLoadingSpacing.medium) {
            timeline
            rowCard
        }
    }

    private var timeline: some View {
        VStack(spacing: 0) {
            JourneyTimelineDaySegment(
                dayCount: 3,
                highlightedDayIndex: highlightedTopDay
            )

            Circle()
                .fill(
                    isCurrent
                        ? BabyLoadingColors.selectionAccent
                        : BabyLoadingColors.passiveTimelineMarker
                )
                .frame(width: isCurrent ? 14 : 8, height: isCurrent ? 14 : 8)
                .overlay {
                    if isCurrent {
                        Circle()
                            .strokeBorder(.white, lineWidth: 2)
                    }
                }

            JourneyTimelineDaySegment(
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
            RoundedRectangle(cornerRadius: BabyLoadingShape.timelineCardCornerRadius, style: .continuous)
                .fill(
                    isCurrent
                        ? BabyLoadingColors.primaryCardSurface
                        : BabyLoadingColors.secondaryCardSurface
                )
        )
        .shadow(
            color: isCurrent
                ? BabyLoadingElevation.selectedTimelineCard.color
                : .clear,
            radius: BabyLoadingElevation.selectedTimelineCard.radius,
            x: BabyLoadingElevation.selectedTimelineCard.horizontalOffset,
            y: BabyLoadingElevation.selectedTimelineCard.verticalOffset
        )
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
                    .strokeBorder(BabyLoadingColors.selectionAccent.opacity(0.2), lineWidth: 1.5)
                    .frame(width: 40, height: 40)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(weekLabel)
                    .font(
                        BabyLoadingTypography.text(
                            .headline,
                            weight: isCurrent ? .bold : .medium
                        )
                    )

                Text(content.babySizeLabel.capitalized(with: locale))
                    .font(BabyLoadingTypography.text(.caption))
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(Text(babySizeAccessibilityLabel))
            }
        }
    }

    private var currentWeekBadge: some View {
        Text("journey.youAreHere")
            .font(BabyLoadingTypography.text(.caption2, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, BabyLoadingSpacing.extraSmall)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                BabyLoadingColors.selectionAccent,
                                BabyLoadingColors.selectionGradientEnd
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .accessibilityHidden(true)
    }

    private var weekLabel: String {
        String(
            format: String(localized: "common.week", defaultValue: "Week %d", locale: locale),
            locale: locale,
            content.week
        )
    }

    private var babySizeAccessibilityLabel: String {
        String(
            format: String(
                localized: "dashboard.babySize",
                defaultValue: "Your baby is now about the size of %@",
                locale: locale
            ),
            locale: locale,
            content.babySizeLabel
        )
    }
}

private struct JourneyTimelineDaySegment: View {
    let dayCount: Int
    let highlightedDayIndex: Int?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Rectangle()
                    .fill(BabyLoadingColors.timelineLine)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)

                ForEach(0 ..< dayCount, id: \.self) { index in
                    let isHighlighted = index == highlightedDayIndex
                    let yPosition = proxy.size.height * (CGFloat(index + 1) / 4)

                    Circle()
                        .fill(
                            isHighlighted
                                ? BabyLoadingColors.selectionAccent
                                : BabyLoadingColors.emphasizedTimelineMarker
                        )
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
