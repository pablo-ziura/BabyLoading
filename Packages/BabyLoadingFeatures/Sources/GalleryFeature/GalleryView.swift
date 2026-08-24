#if os(iOS)
import BabyLoadingDesignComponents
import BabyLoadingDesignTokens
import BabyLoadingNavigation
import BellyTracking
import SwiftUI

public struct GalleryView: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.locale) var locale
    @Environment(AppRouter.self) var router
    @Environment(GalleryViewModel.self) var viewModel

    public init() {}

    public var body: some View {
        ZStack {
            GradientBackground()

            ScrollView {
                VStack(spacing: 20) {
                    header
                    bellyTrackingSection
                    ultrasoundGallerySection
                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
                .padding(.top, 24)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
        .alert(item: activeAlertBinding, content: alert)
        .onChange(of: viewModel.selectedPhotoPickerItems) { _, selectedItems in
            guard !selectedItems.isEmpty else { return }
            Task {
                await viewModel.importSelectedPhotos()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("tabs.gallery")
                .font(BabyLoadingTypography.text(.title2, weight: .bold))
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h1)

            Text("gallery.subtitle")
                .font(BabyLoadingTypography.text(.body))
                .foregroundStyle(.primary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    private var activeAlertBinding: Binding<GalleryAlertState?> {
        Binding(
            get: { viewModel.activeAlert },
            set: { alertState in
                if alertState == nil {
                    viewModel.clearActiveAlert()
                }
            }
        )
    }

    private func alert(_ alertState: GalleryAlertState) -> Alert {
        switch alertState {
        case let .confirmBellyTrackingDeletion(entry):
            deletionConfirmationAlert(for: entry)
        case .photoLibraryPermissionDenied:
            photoLibraryWarningAlert(
                message: String(
                    localized: "gallery.photoLibraryExportDeniedMessage",
                    defaultValue: """
                    The photo was saved in the app, but not in your photo library \
                    because Photos access is disabled.
                    """,
                    locale: locale
                )
            )
        case .photoLibraryExportFailed:
            photoLibraryWarningAlert(
                message: String(
                    localized: "gallery.photoLibraryExportFailedMessage",
                    defaultValue: """
                    The photo was saved in the app, but we couldn't export it \
                    to your photo library.
                    """,
                    locale: locale
                )
            )
        }
    }

    private func deletionConfirmationAlert(for entry: BellyTrackingEntry) -> Alert {
        Alert(
            title: Text(
                String(
                    localized: "gallery.bellyTracking.deleteEntryTitle",
                    defaultValue: "Delete tracking photo?",
                    locale: locale
                )
            ),
            message: Text(
                String(
                    localized: "gallery.bellyTracking.deleteEntryMessage",
                    defaultValue: "This photo will be removed from your belly tracking timeline.",
                    locale: locale
                )
            ),
            primaryButton: .destructive(
                Text(
                    String(
                        localized: "gallery.bellyTracking.deleteEntryConfirm",
                        defaultValue: "Delete",
                        locale: locale
                    )
                )
            ) {
                Task {
                    await viewModel.deleteBellyTrackingEntry(id: entry.id)
                }
            },
            secondaryButton: .cancel(
                Text(String(localized: "common.cancel", defaultValue: "Cancel", locale: locale))
            )
        )
    }

    private func photoLibraryWarningAlert(message: String) -> Alert {
        Alert(
            title: Text(
                String(
                    localized: "gallery.photoLibraryExportTitle",
                    defaultValue: "Photo library sync",
                    locale: locale
                )
            ),
            message: Text(message),
            dismissButton: .default(
                Text(String(localized: "common.ok", defaultValue: "OK", locale: locale))
            )
        )
    }
}
#endif
