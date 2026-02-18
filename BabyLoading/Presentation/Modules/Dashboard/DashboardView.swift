import SwiftUI

struct DashboardView: View {
    var viewModel: BabyProgressViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: - Header
                VStack(spacing: 4) {
                    Text("Baby Loading…")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("Tu aventura semana a semana 🌸")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.top, 24)

                // MARK: - Hero Fruit (Glassmorphism Card)
                heroFruitSection

                // MARK: - Stats Cards
                statsSection

                Spacer(minLength: 100)
            }
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Hero Fruit Section

    private var heroFruitSection: some View {
        VStack(spacing: 16) {
            if let babySize = viewModel.currentBabySize {
                // Glassmorphism card
                VStack(spacing: 16) {
                    // Circular fruit image
                    ZStack {
                        // Outer glow
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

                        // White circle background
                        Circle()
                            .fill(.white)
                            .frame(width: 160, height: 160)
                            .shadow(color: .pink.opacity(0.2), radius: 16, y: 8)

                        // Fruit image clipped to circle
                        Image(babySize.imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 130, height: 130)
                            .clipShape(Circle())

                        // Soft border ring
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

                    Text("Tu bebé ahora es del tamaño de \(babySize.description)")
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

            } else {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundStyle(.white.opacity(0.5))

                    Text("Configura tu fecha en Ajustes")
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

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(spacing: 12) {
            if let week = viewModel.pregnancyWeek {
                HStack(spacing: 16) {
                    StatCard(
                        title: "Semana",
                        value: "\(week)",
                        icon: "calendar.circle.fill"
                    )
                    StatCard(
                        title: "Días restantes",
                        value: "\(viewModel.daysRemaining ?? 0)",
                        icon: "clock.fill"
                    )
                }
                .padding(.horizontal)
            }

            if let fpp = viewModel.estimatedDueDate {
                VStack(spacing: 6) {
                    Text("Fecha probable de parto")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(fpp.formatted(date: .long, time: .omitted))
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(.pink)
                }
                .softCard()
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.pink, .purple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(value)
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .softCard()
    }
}

#Preview {
    ZStack {
        GradientBackground()
        DashboardView(viewModel: BabyProgressViewModel())
    }
}
