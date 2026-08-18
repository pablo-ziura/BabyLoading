import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: BabyProgressViewModel
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.locale) private var locale

    private var isLandscape: Bool { verticalSizeClass == .compact }

    var body: some View {
        ZStack {
            GradientBackground()

            ScrollView {
                VStack(spacing: 24) {
                    Text("settings.title")
                        .font(BabyLoadingTypography.text(.title2, weight: .bold))
                        .foregroundStyle(.primary)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h1)
                        .padding(.top, 24)

                    VStack(spacing: 0) {
                        Text("settings.lastPeriodPrompt")
                            .font(BabyLoadingTypography.text(.headline))
                            .foregroundStyle(.secondary)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityHeading(.h2)
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
                        .environment(\.locale, locale)
                        .tint(.pink)

                        if let fpp = viewModel.estimatedDueDate {
                            Divider().padding(.vertical, 8)
                            VStack(spacing: 4) {
                                Text("settings.dueDate")
                                    .font(BabyLoadingTypography.text(.caption))
                                    .foregroundStyle(.secondary)
                                Text(fpp.formatted(.dateTime.year().month(.wide).day().locale(locale)))
                                    .font(BabyLoadingTypography.text(.headline))
                                    .foregroundStyle(.primary)
                            }
                            .padding(.bottom, 8)
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .softCard()
                    .padding(.horizontal)

                    Button {
                        viewModel.updateDate(viewModel.lastPeriodDate)
                    } label: {
                        Text("settings.setDate")
                            .font(BabyLoadingTypography.text(.headline, weight: .semibold))
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
                    .accessibilityHint(Text("accessibility.settings.setDateHint"))

                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .font(.title3)
                                .foregroundStyle(.pink)
                                .frame(width: 44, height: 44)
                                .background(Color.pink.opacity(0.12), in: Circle())
                                .accessibilityHidden(true)

                            Text("settings.language")
                                .font(BabyLoadingTypography.text(.headline, weight: .semibold))
                                .foregroundStyle(.primary)
                                .accessibilityAddTraits(.isHeader)
                                .accessibilityHeading(.h2)
                        }

                        VStack(spacing: 8) {
                            ForEach(viewModel.availableLanguages) { language in
                                LanguageOptionButton(
                                    language: language,
                                    isSelected: language == viewModel.selectedLanguage
                                ) {
                                    viewModel.updateLanguage(language)
                                }
                            }
                        }
                    }
                    .softCard()
                    .padding(.horizontal)

                    VStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.title3)
                            .foregroundStyle(.primary.opacity(0.6))
                            .accessibilityHidden(true)

                        Text("settings.info")
                            .font(BabyLoadingTypography.text(.caption))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Text(
                            String(
                                format: String(
                                    localized: "settings.version",
                                    defaultValue: "Version %@",
                                    locale: locale
                                ),
                                locale: locale,
                                viewModel.appVersion
                            )
                        )
                        .font(BabyLoadingTypography.text(.caption))
                        .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                    .accessibilityElement(children: .combine)

                    Spacer(minLength: 100)
                }
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct LanguageOptionButton: View {
    let language: AppLanguage
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(language.nativeName)
                    .font(BabyLoadingTypography.text(.headline, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer(minLength: 16)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.pink : Color.secondary.opacity(0.55))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                isSelected ? Color.pink.opacity(0.12) : Color.secondary.opacity(0.06),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.pink.opacity(0.45) : Color.secondary.opacity(0.12),
                        lineWidth: 1
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(language.nativeName))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    ZStack {
        GradientBackground()
        SettingsView(viewModel: BabyProgressViewModel())
    }
}
