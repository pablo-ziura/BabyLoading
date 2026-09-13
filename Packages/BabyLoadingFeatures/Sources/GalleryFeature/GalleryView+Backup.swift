#if os(iOS)
import BabyLoadingDesignComponents
import BabyLoadingDesignTokens
import CloudBackup
import SwiftUI

extension GalleryView {
    @ViewBuilder
    var backupBanner: some View {
        if viewModel.backupState.isGuest {
            VStack(alignment: .leading, spacing: BabyLoadingSpacing.small) {
                Text("backup.gallery.guest")
                    .font(BabyLoadingTypography.text(.body))
                Button("backup.title") { router.selectedTab = .settings }
                    .font(BabyLoadingTypography.text(.headline, weight: .semibold))
                    .frame(minHeight: 44)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .softCard()
        }
        if let failure = viewModel.backupState.failure ?? viewModel.backupState.records.compactMap(\.failure).first {
            VStack(alignment: .leading, spacing: BabyLoadingSpacing.small) {
                Text(LocalizedStringKey("backup.error.\(failure.rawValue)"))
                    .font(BabyLoadingTypography.text(.body))
                Button("backup.retry", action: viewModel.retryBackup)
                    .font(BabyLoadingTypography.text(.headline, weight: .semibold))
                    .frame(minHeight: 44)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .softCard()
        }
    }

    @ViewBuilder
    func backupBadge(origin: BackupPhotoOrigin, sourceID: String) -> some View {
        if let record = viewModel.backupRecord(origin: origin, sourceID: sourceID) {
            Group {
                if record.failure != nil {
                    Image(systemName: "exclamationmark.icloud")
                } else if record.syncStatus == .uploading {
                    ProgressView()
                } else {
                    Image(systemName: record.syncStatus == .synced ? "checkmark.icloud" : "clock")
                }
            }
            .foregroundStyle(.primary)
            .padding(BabyLoadingSpacing.small)
            .background(.white, in: Capsule())
            .padding(BabyLoadingSpacing.small)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(LocalizedStringKey(
                record.failure == nil ? "backup.status.\(record.syncStatus.rawValue)" : "backup.status.failed"
            )))
        }
    }
}
#endif
