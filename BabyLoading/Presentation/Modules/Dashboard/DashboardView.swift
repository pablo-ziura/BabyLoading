import BabyLoadingDesignTokens
import PregnancyContent
import SwiftUI

struct DashboardView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.locale) private var locale
    @Environment(BabyProgressViewModel.self) private var viewModel

    var body: some View {
        ZStack {
            GradientBackground()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("dashboard.title")
                            .font(BabyLoadingTypography.text(.largeTitle, weight: .bold))
                            .foregroundStyle(.primary)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityHeading(.h1)

                        Text("dashboard.subtitle")
                            .font(BabyLoadingTypography.text(.subheadline))
                            .foregroundStyle(.primary.opacity(0.75))
                    }
                    .padding(.top, 24)

                    heroFruitSection

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

    private var heroFruitSection: some View {
        Group {
            if let content = viewModel.currentWeekContent {
                VStack(spacing: 16) {
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
                            .fill(.white)
                            .frame(width: 160, height: 160)
                            .shadow(
                                color: BabyLoadingColors.selectionAccent.opacity(0.2),
                                radius: 16,
                                y: 8
                            )
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

                    Text(
                        String(
                            format: String(
                                localized: "dashboard.babySize",
                                defaultValue: "Your baby is now about the size of %@",
                                locale: locale
                            ),
                            locale: locale,
                            content.babySizeLabel
                        )
                    )
                        .font(BabyLoadingTypography.text(.body, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .padding(.vertical, 24)
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
            } else if viewModel.pregnancyWeek == nil {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundStyle(.primary.opacity(0.45))
                        .accessibilityHidden(true)

                    Text("dashboard.configureDate")
                        .font(BabyLoadingTypography.text(.body))
                        .foregroundStyle(.primary.opacity(0.75))
                }
                .padding(.vertical, 24)
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
    }

    private var statsSection: some View {
        VStack(spacing: 12) {
            if let week = viewModel.pregnancyWeek {
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(spacing: 12) {
                            statsCards(for: week)
                        }
                    } else {
                        HStack(spacing: 16) {
                            statsCards(for: week)
                        }
                    }
                }
                .padding(.horizontal)
            }

            if let fpp = viewModel.estimatedDueDate {
                VStack(spacing: 6) {
                    Text("dashboard.dueDate")
                        .font(BabyLoadingTypography.text(.caption))
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(Text("settings.dueDate"))
                    Text(fpp.formatted(.dateTime.year().month(.wide).day().locale(locale)))
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

    private var developmentSection: some View {
        Group {
            if let content = viewModel.currentWeekContent {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Text("🐣")
                            .font(.title2)
                            .accessibilityHidden(true)
                        Text(content.milestoneTitle)
                            .font(BabyLoadingTypography.text(.headline, weight: .bold))
                            .foregroundStyle(.primary)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityHeading(.h2)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(content.keyEvents.enumerated()), id: \.offset) { _, event in
                            HStack(alignment: .top, spacing: 8) {
                                Text("✨")
                                    .font(.caption)
                                    .accessibilityHidden(true)
                                Text(event)
                                    .font(BabyLoadingTypography.text(.subheadline))
                                    .foregroundStyle(.primary.opacity(0.9))
                            }
                            .padding(.vertical, 8)
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
                        HStack(alignment: .top, spacing: 8) {
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
    }

    @ViewBuilder
    private func statsCards(for week: Int) -> some View {
        StatCard(
            title: String(localized: "dashboard.stats.week", defaultValue: "Week", locale: locale),
            value: "\(week)",
            icon: "calendar.circle.fill"
        )

        StatCard(
            title: String(localized: "dashboard.stats.daysRemaining", defaultValue: "Days remaining", locale: locale),
            value: "\(viewModel.daysRemaining ?? 0)",
            icon: "clock.fill"
        )
    }
}

#Preview {
    let coordinator = Coordinator()
    ZStack {
        GradientBackground()
        DashboardView()
            .environment(coordinator.viewModel)
    }
}
