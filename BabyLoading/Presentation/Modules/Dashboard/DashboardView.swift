import SwiftUI

struct DashboardView: View {
    var viewModel: BabyProgressViewModel

    var body: some View {
        ZStack {
            GradientBackground()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("dashboard.title")
                            .font(.system(.largeTitle, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text("dashboard.subtitle")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(.top, 24)

                    heroFruitSection

                    Text("✨")
                        .font(.title2)
                        .opacity(0.5)

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

                        Circle()
                            .fill(.white)
                            .frame(width: 160, height: 160)
                            .shadow(color: .pink.opacity(0.2), radius: 16, y: 8)

                        Image(content.babySize.imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 130, height: 130)
                            .clipShape(Circle())

                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white, .pink.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 160, height: 160)
                    }

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
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
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
            } else if viewModel.pregnancyWeek == nil {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundStyle(.white.opacity(0.5))

                    Text("dashboard.configureDate")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal, 20)
            }
        }
    }

    private var statsSection: some View {
        VStack(spacing: 12) {
            if let week = viewModel.pregnancyWeek {
                HStack(spacing: 16) {
                    StatCard(
                        title: String(localized: "dashboard.stats.week", defaultValue: "Week"),
                        value: "\(week)",
                        icon: "calendar.circle.fill"
                    )
                    StatCard(
                        title: String(localized: "dashboard.stats.daysRemaining", defaultValue: "Days remaining"),
                        value: "\(viewModel.daysRemaining ?? 0)",
                        icon: "clock.fill"
                    )
                }
                .padding(.horizontal)
            }

            if let fpp = viewModel.estimatedDueDate {
                VStack(spacing: 6) {
                    Text("dashboard.dueDate")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                    Text(fpp.formatted(date: .long, time: .omitted))
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
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
                        Text(content.milestoneTitle)
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(content.keyEvents.enumerated()), id: \.offset) { _, event in
                            HStack(alignment: .top, spacing: 8) {
                                Text("✨")
                                    .font(.caption)
                                Text(event)
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(.primary.opacity(0.9))
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(.pink.opacity(0.08))
                            )
                        }
                    }

                    if let impact = content.physiologicalImpact {
                        HStack(alignment: .top, spacing: 8) {
                            Text("💕")
                                .font(.subheadline)
                            Text(impact)
                                .font(.system(.footnote, design: .rounded))
                                .foregroundStyle(.primary.opacity(0.75))
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.purple.opacity(0.06))
                        )
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
}

#Preview {
    ZStack {
        GradientBackground()
        DashboardView(viewModel: BabyProgressViewModel())
    }
}
