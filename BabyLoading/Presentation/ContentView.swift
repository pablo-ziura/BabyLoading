import SwiftUI

struct ContentView: View {
    @State private var viewModel = BabyProgressViewModel()
    @Environment(\.scenePhase) private var scenePhase

    private let gradientTop = Color(red: 1.0, green: 0.75, blue: 0.82) // Rosa suave
    private let gradientBottom = Color(red: 0.78, green: 0.72, blue: 0.96) // Lavanda

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [gradientTop, gradientBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Baby Loading…")
                            .font(.system(.largeTitle, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text("¿Cuándo es el gran día?")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(.top, 30)

                    DatePicker(
                        "Fecha del evento",
                        selection: $viewModel.eventDate,
                        in: Date.now...,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .environment(\.locale, .current)
                    .tint(.pink)
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 12, y: 6)
                    .padding(.horizontal)

                    Button {
                        viewModel.updateDate(viewModel.eventDate)
                    } label: {
                        Text("Fijar fecha ✨")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.pink, .purple.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: .pink.opacity(0.4), radius: 10, y: 5)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 8)

                    if let days = viewModel.daysRemaining {
                        VStack(spacing: 10) {
                            Text("⏳ Faltan **\(days) días**")
                                .font(.title3)
                                .foregroundStyle(.primary)

                            if let week = viewModel.pregnancyWeek {
                                Text("Semana **\(week)** de embarazo")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }

                            if let size = viewModel.babySizeString {
                                Divider()
                                    .padding(.horizontal, 40)
                                Text("Tu bebé ahora es del tamaño de \(size)")
                                    .font(.subheadline)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 30)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
