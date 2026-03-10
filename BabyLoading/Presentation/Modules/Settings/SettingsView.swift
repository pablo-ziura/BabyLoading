import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: BabyProgressViewModel
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isLandscape: Bool { verticalSizeClass == .compact }

    var body: some View {
        ZStack {
            GradientBackground()

            ScrollView {
                VStack(spacing: 24) {
                    Text("settings.title")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.top, 24)

                    VStack(spacing: 0) {
                        Text("settings.lastPeriodPrompt")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 8)

                        Group {
                            if isLandscape {
                                DatePicker(
                                    "settings.lastPeriodDate",
                                    selection: $viewModel.lastPeriodDate,
                                    in: ...Date.now,
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.compact)
                            } else {
                                DatePicker(
                                    "settings.lastPeriodDate",
                                    selection: $viewModel.lastPeriodDate,
                                    in: ...Date.now,
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.graphical)
                            }
                        }
                        .environment(\.locale, .current)
                        .tint(.pink)

                        if let fpp = viewModel.estimatedDueDate {
                            Divider().padding(.vertical, 8)
                            VStack(spacing: 4) {
                                Text("settings.dueDate")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                                Text(fpp.formatted(date: .long, time: .omitted))
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundStyle(.pink)
                            }
                            .padding(.bottom, 8)
                        }
                    }
                    .softCard()
                    .padding(.horizontal)

                    Button {
                        viewModel.updateDate(viewModel.lastPeriodDate)
                    } label: {
                        Text("settings.setDate")
                            .font(.system(.headline, design: .rounded))
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

                    VStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.6))

                        Text("settings.info")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 8)

                    Spacer(minLength: 100)
                }
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    ZStack {
        GradientBackground()
        SettingsView(viewModel: BabyProgressViewModel())
    }
}
