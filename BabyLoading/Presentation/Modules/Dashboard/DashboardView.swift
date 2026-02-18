import SwiftUI

struct DashboardView: View {
    var viewModel: BabyProgressViewModel

    var body: some View {
        ZStack {
            GradientBackground()

            ScrollView {
                VStack(spacing: 24) {
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

                    heroFruitSection

                    statsSection

                    Spacer(minLength: 100)
                }
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var heroFruitSection: some View {
        VStack(spacing: 16) {
            if let babySize = viewModel.currentBabySize {
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

                        Image(babySize.imageName)
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

#Preview {
    ZStack {
        GradientBackground()
        DashboardView(viewModel: BabyProgressViewModel())
    }
}
