import BabyLoadingDesignComponents
import BabyLoadingDesignTokens
import BabyLoadingNavigation
import BellyTracking
import PhotosUI
import SwiftUI
import UltrasoundGallery
#if canImport(UIKit)
    import UIKit
#endif

struct GalleryView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.locale) private var locale
    @Environment(AppRouter.self) private var router
    @Environment(GalleryViewModel.self) private var viewModel

    private var photoColumns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            [GridItem(.flexible(), spacing: 12)]
        } else {
            [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ]
        }
    }

    var body: some View {
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
        .alert(item: activeAlertBinding) { alertState in
            switch alertState {
            case let .confirmBellyTrackingDeletion(entry):
                return Alert(
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
            case .photoLibraryPermissionDenied:
                return Alert(
                    title: Text(
                        String(
                            localized: "gallery.photoLibraryExportTitle",
                            defaultValue: "Photo library sync",
                            locale: locale
                        )
                    ),
                    message: Text(
                        String(
                            localized: "gallery.photoLibraryExportDeniedMessage",
                            defaultValue: """
                            The photo was saved in the app, but not in your photo library \
                            because Photos access is disabled.
                            """,
                            locale: locale
                        )
                    ),
                    dismissButton: .default(
                        Text(String(localized: "common.ok", defaultValue: "OK", locale: locale))
                    )
                )
            case .photoLibraryExportFailed:
                return Alert(
                    title: Text(
                        String(
                            localized: "gallery.photoLibraryExportTitle",
                            defaultValue: "Photo library sync",
                            locale: locale
                        )
                    ),
                    message: Text(
                        String(
                            localized: "gallery.photoLibraryExportFailedMessage",
                            defaultValue: """
                            The photo was saved in the app, but we couldn't export it \
                            to your photo library.
                            """,
                            locale: locale
                        )
                    ),
                    dismissButton: .default(
                        Text(String(localized: "common.ok", defaultValue: "OK", locale: locale))
                    )
                )
            }
        }
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

    private var bellyTrackingSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("gallery.bellyTracking.title")
                        .font(BabyLoadingTypography.text(.title3, weight: .bold))

                    Text("gallery.bellyTracking.subtitle")
                        .font(BabyLoadingTypography.text(.subheadline))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                dueBadge
            }

            HStack(spacing: 12) {
                statCard(
                    title: String(
                        localized: "gallery.bellyTracking.totalPhotos",
                        defaultValue: "Tracking photos"
                    ),
                    value: "\(viewModel.bellyTrackingEntries.count)"
                )

                TimelineView(.periodic(from: .now, by: 60)) { context in
                    statCard(
                        title: String(
                            localized: "gallery.bellyTracking.nextPhoto",
                            defaultValue: "Next photo"
                        ),
                        value: nextPhotoValue(for: viewModel.bellyTrackingStatus(asOf: context.date))
                    )
                }
            }

            if let lastEntry = viewModel.lastBellyTrackingEntry {
                lastCaptureCard(entry: lastEntry)
            } else {
                emptyBellyTrackingState
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("gallery.bellyTracking.cadence")
                    .font(BabyLoadingTypography.text(.subheadline, weight: .semibold))

                Picker(
                    String(
                        localized: "gallery.bellyTracking.cadence",
                        defaultValue: "Cadence"
                    ),
                    selection: Binding(
                        get: { viewModel.bellyTrackingSettings.intervalDays },
                        set: { intervalDays in
                            Task {
                                await viewModel.updateBellyTrackingCadence(
                                    intervalDays: intervalDays
                                )
                            }
                        }
                    )
                ) {
                    ForEach(BellyTrackingSettings.supportedIntervals, id: \.self) { interval in
                        Text(intervalLabel(interval))
                            .tag(interval)
                    }
                }
                .pickerStyle(.segmented)
            }

            Button {
                router.present(.bellyTrackingCamera)
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("gallery.bellyTracking.takePhoto")
                }
                .font(BabyLoadingTypography.text(.headline, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    BabyLoadingColors.selectionAccent.opacity(0.16),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
            }
            .buttonStyle(.plain)

            if !viewModel.bellyTrackingEntries.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("gallery.bellyTracking.timelineTitle")
                        .font(BabyLoadingTypography.text(.subheadline, weight: .semibold))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(viewModel.bellyTrackingEntries) { entry in
                                bellyTrackingTimelineCard(entry: entry)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .animation(
            .spring(duration: 0.3),
            value: viewModel.bellyTrackingEntries.map(\.id)
        )
        .softCard()
    }

    private func lastCaptureCard(entry: BellyTrackingEntry) -> some View {
        HStack(spacing: 14) {
            previewImage(data: viewModel.bellyTrackingImageData(for: entry))
                .frame(width: 104, height: 136)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                Text("gallery.bellyTracking.lastCapture")
                    .font(BabyLoadingTypography.text(.subheadline, weight: .semibold))

                Text(entry.capturedAt.formatted(.dateTime.year().month(.abbreviated).day().locale(locale)))
                    .font(BabyLoadingTypography.text(.body))
                    .foregroundStyle(.primary.opacity(0.8))

                if let week = entry.pregnancyWeekAtCapture {
                    Text(weekLabel(week))
                        .font(BabyLoadingTypography.text(.caption))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            BabyLoadingColors.selectionAccent.opacity(0.14),
                            in: Capsule()
                        )
                }
            }

            Spacer()
        }
    }

    private var emptyBellyTrackingState: some View {
        VStack(spacing: 10) {
            Image(systemName: "figure.stand.line.dotted.figure.stand")
                .font(.system(size: 34))
                .foregroundStyle(BabyLoadingColors.selectionAccent.opacity(0.7))
                .accessibilityHidden(true)

            Text("gallery.bellyTracking.emptyTitle")
                .font(BabyLoadingTypography.text(.headline, weight: .semibold))

            Text("gallery.bellyTracking.emptySubtitle")
                .font(BabyLoadingTypography.text(.subheadline))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private var ultrasoundGallerySection: some View {
        let isImportingPhotos = viewModel.isImportingPhotos

        return VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("gallery.title")
                    .font(BabyLoadingTypography.text(.title3, weight: .bold))

                Text("gallery.freePhotosSubtitle")
                    .font(BabyLoadingTypography.text(.subheadline))
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: photoColumns, spacing: 12) {
                ForEach(viewModel.ultrasoundPhotos) { photo in
                    if let uiImage = UIImage(data: photo.data) {
                        ZStack(alignment: .topTrailing) {
                            Color.clear
                                .frame(height: 180)
                                .overlay {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .accessibilityLabel(
                                            Text(
                                                photoAccessibilityLabel(
                                                    index: ultrasoundPhotoIndex(photo),
                                                    total: viewModel.ultrasoundPhotos.count
                                                )
                                            )
                                        )
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

                            Button {
                                Task {
                                    await viewModel.deleteUltrasoundPhoto(id: photo.id)
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .black.opacity(0.5))
                                    .padding(8)
                            }
                            .accessibilityLabel(
                                Text(
                                    deletePhotoAccessibilityLabel(
                                        index: ultrasoundPhotoIndex(photo),
                                        total: viewModel.ultrasoundPhotos.count
                                    )
                                )
                            )
                            .accessibilityHint(Text("accessibility.gallery.deletePhotoHint"))
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }

                PhotosPicker(
                    selection: photoPickerSelectionBinding,
                    maxSelectionCount: 10,
                    matching: .images
                ) {
                    VStack(spacing: 10) {
                        if isImportingPhotos {
                            ProgressView()
                                .accessibilityLabel(Text("gallery.addPhoto"))
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.primary.opacity(0.75))
                                .accessibilityHidden(true)

                            Text("gallery.addPhoto")
                                .font(BabyLoadingTypography.text(.caption, weight: .medium))
                                .foregroundStyle(.primary.opacity(0.75))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .background(.ultraThinMaterial.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(.white.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                    )
                }
                .disabled(isImportingPhotos)
                .accessibilityHint(Text("accessibility.gallery.addPhotoHint"))
            }
            .animation(.spring(duration: 0.3), value: viewModel.ultrasoundPhotos.map(\.id))

            if viewModel.ultrasoundPhotos.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 40))
                        .foregroundStyle(.primary.opacity(0.45))
                        .accessibilityHidden(true)

                    Text("gallery.emptyTitle")
                        .font(BabyLoadingTypography.text(.body))
                        .foregroundStyle(.primary.opacity(0.8))

                    Text("gallery.emptySubtitle")
                        .font(BabyLoadingTypography.text(.caption))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 12)
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
            }
        }
        .softCard()
    }

    private var dueBadge: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            statusBadge(for: viewModel.bellyTrackingStatus(asOf: context.date))
        }
    }

    private func statusBadge(for status: BellyTrackingStatus) -> some View {
        let titleKey: LocalizedStringKey
        let backgroundColor: Color

        switch status {
        case .upToDate:
            titleKey = "gallery.bellyTracking.onTrack"
            backgroundColor = BabyLoadingColors.positiveStatusSurface
        case .needsInitialCapture:
            titleKey = "gallery.bellyTracking.startNow"
            backgroundColor = BabyLoadingColors.attentionStatusSurface
        case .pending:
            titleKey = "gallery.bellyTracking.dueNow"
            backgroundColor = BabyLoadingColors.attentionStatusSurface
        }

        return Text(titleKey)
            .font(BabyLoadingTypography.text(.caption, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(backgroundColor, in: Capsule())
            .accessibilityLabel(Text(titleKey))
    }

    private func nextPhotoValue(for status: BellyTrackingStatus) -> String {
        switch status {
        case .needsInitialCapture:
            return String(localized: "gallery.bellyTracking.startNow", defaultValue: "Start now", locale: locale)
        case .upToDate(let nextDueDate):
            return nextDueDate.formatted(.dateTime.year().month(.abbreviated).day().locale(locale))
        case .pending:
            return String(localized: "gallery.bellyTracking.dueNow", defaultValue: "Ready now", locale: locale)
        }
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(BabyLoadingTypography.text(.caption))
                .foregroundStyle(.secondary)

            Text(value)
                .font(BabyLoadingTypography.text(.headline, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func bellyTrackingTimelineCard(entry: BellyTrackingEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                previewImage(data: viewModel.bellyTrackingImageData(for: entry))
                    .frame(width: 148, height: 190)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Button {
                    viewModel.requestBellyTrackingDeletion(entry)
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.45))
                        .padding(8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("gallery.bellyTracking.deleteEntryConfirm"))
            }

            Text(entry.capturedAt.formatted(.dateTime.year().month(.abbreviated).day().locale(locale)))
                .font(BabyLoadingTypography.text(.subheadline, weight: .semibold))

            if let week = entry.pregnancyWeekAtCapture {
                Text(weekLabel(week))
                    .font(BabyLoadingTypography.text(.caption))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 148, alignment: .leading)
    }

    @ViewBuilder
    private func previewImage(data: Data?) -> some View {
        if let data, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.8))

                Image(systemName: "photo.badge.exclamationmark")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var photoPickerSelectionBinding: Binding<[PhotosPickerItem]> {
        Binding(
            get: { viewModel.selectedPhotoPickerItems },
            set: { viewModel.selectedPhotoPickerItems = $0 }
        )
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

    private func intervalLabel(_ interval: Int) -> String {
        String(
            format: String(
                localized: "gallery.bellyTracking.intervalDays",
                defaultValue: "%d days",
                locale: locale
            ),
            locale: locale,
            interval
        )
    }

    private func weekLabel(_ week: Int) -> String {
        String(
            format: String(
                localized: "common.week",
                defaultValue: "Week %d",
                locale: locale
            ),
            locale: locale,
            week
        )
    }

    private func photoAccessibilityLabel(index: Int, total: Int) -> String {
        String(
            format: String(
                localized: "accessibility.gallery.photoPosition",
                defaultValue: "Ultrasound photo %1$d of %2$d",
                locale: locale
            ),
            locale: locale,
            index + 1,
            total
        )
    }

    private func ultrasoundPhotoIndex(_ photo: UltrasoundPhoto) -> Int {
        viewModel.ultrasoundPhotos.firstIndex(where: { $0.id == photo.id }) ?? 0
    }

    private func deletePhotoAccessibilityLabel(index: Int, total: Int) -> String {
        String(
            format: String(
                localized: "accessibility.gallery.deletePhoto",
                defaultValue: "Delete photo %1$d of %2$d",
                locale: locale
            ),
            locale: locale,
            index + 1,
            total
        )
    }
}

#Preview {
    let coordinator = Coordinator()
    ZStack {
        GradientBackground()
        GalleryView()
            .environment(coordinator.router)
            .environment(coordinator.galleryViewModel)
    }
}
