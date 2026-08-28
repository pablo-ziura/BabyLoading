#if os(iOS)
import BabyLoadingDesignComponents
import BabyLoadingDesignTokens
import BabyLoadingNavigation
import BellyTracking
import Foundation
import SwiftUI
import UIKit

extension GalleryView {
    var bellyTrackingSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("gallery.bellyTracking.title")
                        .font(BabyLoadingTypography.text(.title3, weight: .bold))
                        .accessibilityAddTraits(.isHeader)

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

            cadencePicker

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
                bellyTrackingTimeline
            }
        }
        .animation(.spring(duration: 0.3), value: viewModel.bellyTrackingEntries.map(\.id))
        .softCard()
    }

    private var cadencePicker: some View {
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
                            await viewModel.updateBellyTrackingCadence(intervalDays: intervalDays)
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
    }

    private var bellyTrackingTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("gallery.bellyTracking.timelineTitle")
                .font(BabyLoadingTypography.text(.subheadline, weight: .semibold))
                .accessibilityAddTraits(.isHeader)

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

    private func lastCaptureCard(entry: BellyTrackingEntry) -> some View {
        HStack(spacing: 14) {
            previewImage(data: viewModel.bellyTrackingImageData(for: entry))
                .frame(width: 104, height: 136)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .accessibilityHidden(true)

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
            String(
                localized: "gallery.bellyTracking.startNow",
                defaultValue: "Start now",
                locale: locale
            )
        case let .upToDate(nextDueDate):
            nextDueDate.formatted(.dateTime.year().month(.abbreviated).day().locale(locale))
        case .pending:
            String(
                localized: "gallery.bellyTracking.dueNow",
                defaultValue: "Tracking photo overdue",
                locale: locale
            )
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
        .background(
            Color.white.opacity(0.75),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }

    private func bellyTrackingTimelineCard(entry: BellyTrackingEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                previewImage(data: viewModel.bellyTrackingImageData(for: entry))
                    .frame(width: 148, height: 190)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .accessibilityHidden(true)

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
                .accessibilityLabel(Text(deleteTrackingPhotoAccessibilityLabel(entry)))
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

    private func deleteTrackingPhotoAccessibilityLabel(_ entry: BellyTrackingEntry) -> String {
        let index = viewModel.bellyTrackingEntries.firstIndex(where: { $0.id == entry.id }) ?? 0
        return String(
            format: String(
                localized: "accessibility.gallery.deletePhoto",
                defaultValue: "Delete photo %1$d of %2$d",
                locale: locale
            ),
            locale: locale,
            index + 1,
            viewModel.bellyTrackingEntries.count
        )
    }
}
#endif
