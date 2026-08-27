import BabyLoadingDesignTokens
import BabyProgressWidgetSupport
import Foundation
import PregnancyProgress
import SwiftUI
import WidgetKit

struct BabyProgressWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: BabyProgressWidgetEntry

    private var snapshot: BabyProgressWidgetSnapshot {
        entry.snapshot
    }

    private var locale: Locale {
        Locale(identifier: snapshot.localeIdentifier)
    }

    var body: some View {
        Group {
            switch snapshot.state {
            case .unconfigured:
                emptyStateView
            case .invalidFutureLastPeriodDate:
                invalidDateView
            case let .ongoing(progress, babySizeImageName, babySizeLabel):
                ongoingView(
                    progress: progress,
                    babySizeImageName: babySizeImageName,
                    babySizeLabel: babySizeLabel
                )
            case let .lateTerm(progress):
                phaseView(progress: progress, phase: .lateTerm)
            case let .postTerm(progress):
                phaseView(progress: progress, phase: .postTerm)
            }
        }
        .unredacted()
        .environment(\.locale, locale)
    }

    @ViewBuilder
    private func ongoingView(
        progress: BabyProgressWidgetDetails,
        babySizeImageName: String,
        babySizeLabel: String?
    ) -> some View {
        let completion = min(
            (Double(progress.gestationalAge.weeks) + Double(progress.gestationalAge.days) / 7) / 40,
            1
        )
        let resolvedBabySizeLabel = babySizeLabel ?? String(
            localized: "widget.unknownSize",
            defaultValue: "a mystery",
            locale: locale
        )

        HStack(spacing: 0) {
            fruitProgressRing(progress: completion, babySizeImageName: babySizeImageName)

            VStack(alignment: .leading, spacing: 4) {
                Text(
                    String(
                        format: String(localized: "common.week", defaultValue: "Week %d", locale: locale),
                        locale: locale,
                        progress.gestationalAge.weeks
                    )
                )
                    .font(BabyLoadingTypography.widget(size: 15, weight: .extraBold))
                    .foregroundStyle(.white)

                Text(
                    String(
                        format: String(
                            localized: "widget.babySize",
                            defaultValue: "The baby 🤰🏽 is now about the size of %@",
                            locale: locale
                        ),
                        locale: locale,
                        resolvedBabySizeLabel
                    )
                )
                    .font(BabyLoadingTypography.widget(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.6)

                Spacer(minLength: 4)

                Text(dueDateRelationText(progress.dueDateRelation))
                    .font(BabyLoadingTypography.widget(size: 14, weight: .extraBold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.2))
                            .frame(height: 4)
                        Capsule()
                            .fill(.white)
                            .frame(width: geo.size.width * completion, height: 4)
                    }
                }
                .frame(height: 4)
            }
            .padding(.leading, 10)
        }
        .containerBackground(for: .widget) {
            widgetGradient
        }
    }

    private func phaseView(
        progress: BabyProgressWidgetDetails,
        phase: PregnancyPhase
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 32))
                .foregroundStyle(.white.opacity(0.85))

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(phase == .lateTerm ? "widget.lateTerm" : "widget.postTerm"))
                    .font(BabyLoadingTypography.widget(size: 14, weight: .extraBold))
                    .foregroundStyle(.white)

                Text(gestationalAgeText(progress.gestationalAge))
                    .font(BabyLoadingTypography.widget(size: 18, weight: .extraBold))
                    .foregroundStyle(.white)

                Text(dueDateRelationText(progress.dueDateRelation))
                    .font(BabyLoadingTypography.widget(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Text("widget.reviewDate")
                    .font(BabyLoadingTypography.widget(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(2)
            }
        }
        .containerBackground(for: .widget) {
            widgetGradient
        }
    }

    private var invalidDateView: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.8))

            Text("widget.invalidDate")
                .font(BabyLoadingTypography.widget(size: 13, weight: .medium))
                .multilineTextAlignment(.leading)
                .foregroundStyle(.white.opacity(0.7))
        }
        .containerBackground(for: .widget) {
            widgetGradient
        }
    }

    private func fruitProgressRing(progress: Double, babySizeImageName: String) -> some View {
        let ringSize: CGFloat = family == .systemMedium ? 100 : 74
        let lineWidth: CGFloat = 5
        let imageSize: CGFloat = ringSize - lineWidth * 2

        return ZStack {
            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: ringSize, height: ringSize)

            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: lineWidth)
                .frame(width: ringSize, height: ringSize)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.white,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: ringSize, height: ringSize)

            Image(babySizeImageName)
                .resizable()
                .scaledToFill()
                .frame(width: imageSize, height: imageSize)
                .clipShape(Circle())
        }
    }

    private var emptyStateView: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.8))

            Text("widget.configureDate")
                .font(BabyLoadingTypography.widget(size: 13, weight: .medium))
                .multilineTextAlignment(.leading)
                .foregroundStyle(.white.opacity(0.7))
        }
        .containerBackground(for: .widget) {
            widgetGradient
        }
    }

    private var widgetGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.93, green: 0.55, blue: 0.67),
                Color(red: 0.70, green: 0.55, blue: 0.82)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func gestationalAgeText(_ gestationalAge: GestationalAge) -> String {
        String(
            format: String(
                localized: "widget.gestationalAge",
                defaultValue: "Week %d+%d",
                locale: locale
            ),
            locale: locale,
            gestationalAge.weeks,
            gestationalAge.days
        )
    }

    private func dueDateRelationText(_ relation: DueDateRelation) -> String {
        switch relation {
        case let .upcoming(days):
            String(
                format: String(
                    localized: "widget.daysUntilDueDate",
                    defaultValue: "%d days until estimated due date",
                    locale: locale
                ),
                locale: locale,
                days
            )
        case .today:
            String(localized: "widget.dueDateToday", defaultValue: "Estimated due date today", locale: locale)
        case let .elapsed(days):
            String(
                format: String(
                    localized: "widget.daysSinceDueDate",
                    defaultValue: "%d days since estimated due date",
                    locale: locale
                ),
                locale: locale,
                days
            )
        }
    }
}
