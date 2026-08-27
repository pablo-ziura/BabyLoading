import BabyLoadingDesignComponents
import BabyLoadingDesignTokens
import PregnancyContent
import PregnancyProgress
import SwiftUI

public struct DashboardView: View {
    @Environment(DashboardViewModel.self) private var viewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.locale) private var locale

    public init() {}

    public var body: some View {
        ZStack {
            GradientBackground()

            ScrollView {
                VStack(spacing: BabyLoadingSpacing.large) {
                    header
                    heroSection
                    phaseNotice

                    Text("✨")
                        .font(.title2)
                        .opacity(0.5)
                        .accessibilityHidden(true)

                    statsSection
                    developmentSection
                    Spacer(minLength: 100)
                }
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var header: some View {
        VStack(spacing: BabyLoadingSpacing.extraSmall) {
            Text("dashboard.title")
                .font(BabyLoadingTypography.text(.largeTitle, weight: .bold))
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h1)

            Text("dashboard.subtitle")
                .font(BabyLoadingTypography.text(.subheadline))
                .foregroundStyle(.primary.opacity(0.75))
        }
        .padding(.top, BabyLoadingSpacing.large)
    }

    @ViewBuilder
    private var heroSection: some View {
        if let content = viewModel.currentWeekContent {
            VStack(spacing: BabyLoadingSpacing.medium) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.4), .clear],
                                center: .center,
                                startRadius: 60,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .accessibilityHidden(true)

                    Circle()
                        .fill(BabyLoadingColors.primaryCardSurface)
                        .frame(width: 160, height: 160)
                        .shadow(color: BabyLoadingColors.selectionAccent.opacity(0.2), radius: 16, y: 8)
                        .accessibilityHidden(true)

                    Image(content.babySize.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 130, height: 130)
                        .clipShape(Circle())
                        .accessibilityHidden(true)

                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    BabyLoadingColors.primaryCardSurface,
                                    BabyLoadingColors.selectionAccent.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 160, height: 160)
                        .accessibilityHidden(true)
                }

                Text(babySizeDescription(content.babySizeLabel))
                    .font(BabyLoadingTypography.text(.body, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BabyLoadingSpacing.medium)
            }
            .padding(.vertical, BabyLoadingSpacing.large)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(.white.opacity(0.4), lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .accessibilityElement(children: .combine)
        } else if viewModel.progress == nil {
            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundStyle(.primary.opacity(0.45))
                    .accessibilityHidden(true)

                Text("dashboard.configureDate")
                    .font(BabyLoadingTypography.text(.body))
                    .foregroundStyle(.primary.opacity(0.75))
            }
            .padding(.vertical, BabyLoadingSpacing.large)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal, 20)
            .accessibilityElement(children: .combine)
        } else if isStoredDateInFuture {
            VStack(spacing: BabyLoadingSpacing.small) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 42))
                    .foregroundStyle(.primary.opacity(0.55))
                    .accessibilityHidden(true)

                Text("pregnancy.status.invalidDate.title")
                    .font(BabyLoadingTypography.text(.headline, weight: .bold))
                    .foregroundStyle(.primary)

                Text("pregnancy.status.invalidDate.message")
                    .font(BabyLoadingTypography.text(.body))
                    .foregroundStyle(.primary.opacity(0.75))
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, BabyLoadingSpacing.large)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal, 20)
            .accessibilityElement(children: .combine)
        }
    }

    private var statsSection: some View {
        VStack(spacing: 12) {
            if let activeProgress {
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(spacing: 12) {
                            statCards(progress: activeProgress)
                        }
                    } else {
                        HStack(spacing: BabyLoadingSpacing.medium) {
                            statCards(progress: activeProgress)
                        }
                    }
                }
                .padding(.horizontal)
            }

            if let dueDate = activeProgress?.dueDate {
                VStack(spacing: 6) {
                    Text("dashboard.dueDate")
                        .font(BabyLoadingTypography.text(.caption))
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(Text("settings.dueDate"))

                    Text(dueDate.formatted(.dateTime.year().month(.wide).day().locale(locale)))
                        .font(BabyLoadingTypography.text(.title3, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(.white.opacity(0.35), lineWidth: 1)
                )
                .padding(.horizontal)
                .accessibilityElement(children: .combine)
            }
        }
    }

    @ViewBuilder
    private var developmentSection: some View {
        if let content = viewModel.currentWeekContent {
            VStack(alignment: .leading, spacing: BabyLoadingSpacing.medium) {
                HStack(spacing: BabyLoadingSpacing.small) {
                    Text("🐣")
                        .font(.title2)
                        .accessibilityHidden(true)

                    Text(content.milestoneTitle)
                        .font(BabyLoadingTypography.text(.headline, weight: .bold))
                        .foregroundStyle(.primary)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h2)
                }

                VStack(alignment: .leading, spacing: BabyLoadingSpacing.small) {
                    ForEach(Array(content.keyEvents.enumerated()), id: \.offset) { _, event in
                        HStack(alignment: .top, spacing: BabyLoadingSpacing.small) {
                            Text("✨")
                                .font(.caption)
                                .accessibilityHidden(true)

                            Text(event)
                                .font(BabyLoadingTypography.text(.subheadline))
                                .foregroundStyle(.primary.opacity(0.9))
                        }
                        .padding(.vertical, BabyLoadingSpacing.small)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(BabyLoadingColors.selectionAccent.opacity(0.08))
                        )
                        .accessibilityElement(children: .combine)
                    }
                }

                if let impact = content.physiologicalImpact {
                    HStack(alignment: .top, spacing: BabyLoadingSpacing.small) {
                        Text("💕")
                            .font(.subheadline)
                            .accessibilityHidden(true)

                        Text(impact)
                            .font(BabyLoadingTypography.text(.footnote))
                            .foregroundStyle(.primary.opacity(0.75))
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.purple.opacity(0.06))
                    )
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(.white.opacity(0.4), lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private func statCards(progress: ActivePregnancyProgress) -> some View {
        DashboardStatCard(
            title: String(localized: "dashboard.stats.week", defaultValue: "Week", locale: locale),
            value: "\(progress.gestationalAge.weeks)",
            systemImage: "calendar.circle.fill"
        )

        switch progress.dueDateRelation {
        case let .upcoming(days):
            DashboardStatCard(
                title: String(
                    localized: "dashboard.stats.daysUntilDueDate",
                    defaultValue: "Days until estimated due date",
                    locale: locale
                ),
                value: "\(days)",
                systemImage: "clock.fill"
            )
        case .today:
            DashboardStatCard(
                title: String(
                    localized: "dashboard.stats.dueDate",
                    defaultValue: "Estimated due date",
                    locale: locale
                ),
                value: String(localized: "pregnancy.status.dueDateToday", defaultValue: "Today", locale: locale),
                systemImage: "calendar.badge.clock"
            )
        case let .elapsed(days):
            DashboardStatCard(
                title: String(
                    localized: "dashboard.stats.daysSinceDueDate",
                    defaultValue: "Days since estimated due date",
                    locale: locale
                ),
                value: "\(days)",
                systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90"
            )
        }
    }

    @ViewBuilder
    private var phaseNotice: some View {
        if let activeProgress, activeProgress.phase != .ongoing {
            PregnancyProgressStatusCard(progress: activeProgress)
            .padding(.horizontal)
        }
    }

    private var activeProgress: ActivePregnancyProgress? {
        guard case let .some(.active(progress)) = viewModel.progress else {
            return nil
        }
        return progress
    }

    private var isStoredDateInFuture: Bool {
        guard case .some(.invalidFutureLastPeriodDate) = viewModel.progress else {
            return false
        }
        return true
    }
    private func babySizeDescription(_ babySizeLabel: String) -> String {
        String(
            format: String(
                localized: "dashboard.babySize",
                defaultValue: "Your baby is now about the size of %@",
                locale: locale
            ),
            locale: locale,
            babySizeLabel
        )
    }
}
