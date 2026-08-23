import BabyLoadingDesignComponents
import BabyLoadingDesignTokens
import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif

public struct SettingsView: View {
    @Environment(SettingsViewModel.self) private var viewModel
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.locale) private var locale
    @Environment(\.openURL) private var openURL

    public init() {}

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    public var body: some View {
        ZStack {
            GradientBackground()

            ScrollView {
                VStack(spacing: BabyLoadingSpacing.large) {
                    Text("settings.title")
                        .font(BabyLoadingTypography.text(.title2, weight: .bold))
                        .foregroundStyle(.primary)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h1)
                        .padding(.top, BabyLoadingSpacing.large)

                    dateCard
                    updateDateButton
                    languageCard
                    applicationInformation
                    Spacer(minLength: 100)
                }
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var dateCard: some View {
        VStack(spacing: 0) {
            Text("settings.lastPeriodPrompt")
                .font(BabyLoadingTypography.text(.headline))
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h2)
                .padding(.bottom, BabyLoadingSpacing.small)

            Group {
                if isLandscape {
                    DatePicker(
                        "settings.lastPeriodDate",
                        selection: lastPeriodDateBinding,
                        in: ...Date.now,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                } else {
                    DatePicker(
                        "settings.lastPeriodDate",
                        selection: lastPeriodDateBinding,
                        in: ...Date.now,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                }
            }
            .environment(\.locale, locale)
            .tint(BabyLoadingColors.selectionAccent)

            if let dueDate = viewModel.dueDate {
                Divider()
                    .padding(.vertical, BabyLoadingSpacing.small)

                VStack(spacing: BabyLoadingSpacing.extraSmall) {
                    Text("settings.dueDate")
                        .font(BabyLoadingTypography.text(.caption))
                        .foregroundStyle(.secondary)

                    Text(dueDate.formatted(.dateTime.year().month(.wide).day().locale(locale)))
                        .font(BabyLoadingTypography.text(.headline))
                        .foregroundStyle(.primary)
                }
                .padding(.bottom, BabyLoadingSpacing.small)
                .accessibilityElement(children: .combine)
            }
        }
        .softCard()
        .padding(.horizontal)
    }

    private var updateDateButton: some View {
        Button {
            Task {
                await viewModel.updateLastPeriodDate()
            }
        } label: {
            Group {
                if viewModel.saveState == .saving {
                    ProgressView()
                        .tint(.white)
                        .accessibilityLabel(Text("settings.setDate"))
                } else {
                    Text("settings.setDate")
                        .font(BabyLoadingTypography.text(.headline, weight: .semibold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, BabyLoadingSpacing.medium)
            .background(
                LinearGradient(
                    colors: [
                        BabyLoadingColors.selectionAccent,
                        BabyLoadingColors.selectionGradientEnd
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(
                color: BabyLoadingColors.selectionAccent.opacity(0.4),
                radius: 10,
                y: 5
            )
        }
        .disabled(viewModel.saveState == .saving)
        .padding(.horizontal, 40)
        .accessibilityHint(Text("accessibility.settings.setDateHint"))
    }

    private var languageCard: some View {
        VStack(alignment: .leading, spacing: BabyLoadingSpacing.medium) {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.title3)
                    .foregroundStyle(BabyLoadingColors.selectionAccent)
                    .frame(width: 44, height: 44)
                    .background(BabyLoadingColors.selectionAccent.opacity(0.12), in: Circle())
                    .accessibilityHidden(true)

                Text("settings.language")
                    .font(BabyLoadingTypography.text(.headline, weight: .semibold))
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHeading(.h2)
            }

            VStack(alignment: .leading, spacing: BabyLoadingSpacing.small) {
                Text("settings.language.current")
                    .font(BabyLoadingTypography.text(.caption))
                    .foregroundStyle(.secondary)

                Text(viewModel.appLanguage.nativeName)
                    .font(BabyLoadingTypography.text(.title3, weight: .bold))
                    .foregroundStyle(.primary)

                Text("settings.language.systemManaged")
                    .font(BabyLoadingTypography.text(.body))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: openAppSettings) {
                    Label("settings.language.openSettings", systemImage: "arrow.up.forward.app")
                        .font(BabyLoadingTypography.text(.headline, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(
                            Color.secondary.opacity(0.06),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.secondary.opacity(0.12), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text("accessibility.settings.openLanguageSettingsHint"))
            }
        }
        .softCard()
        .padding(.horizontal)
    }

    private var applicationInformation: some View {
        VStack(spacing: BabyLoadingSpacing.small) {
            Image(systemName: "info.circle")
                .font(.title3)
                .foregroundStyle(.primary.opacity(0.6))
                .accessibilityHidden(true)

            Text("settings.info")
                .font(BabyLoadingTypography.text(.caption))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text(applicationVersionLabel)
                .font(BabyLoadingTypography.text(.caption))
                .foregroundStyle(.secondary)
        }
        .padding(.top, BabyLoadingSpacing.small)
        .accessibilityElement(children: .combine)
    }

    private var lastPeriodDateBinding: Binding<Date> {
        Binding(
            get: { viewModel.lastPeriodDate },
            set: { viewModel.lastPeriodDate = $0 }
        )
    }

    private var applicationVersionLabel: String {
        String(
            format: String(localized: "settings.version", defaultValue: "Version %@", locale: locale),
            locale: locale,
            viewModel.appVersion
        )
    }

    private func openAppSettings() {
        #if canImport(UIKit)
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            openURL(settingsURL)
        #endif
    }
}
