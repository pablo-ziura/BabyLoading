import BellyTracking
import Foundation
import PregnancyProgress
import UltrasoundGallery

public struct InitializeBackupUseCase: Sendable {
    private let store: BackupLocalStore
    private let legacyProgress: any PregnancyProgressStoreProtocol
    private let legacyGallery: any UltrasoundGalleryStoreProtocol
    private let legacyTracking: any BellyTrackingStoreProtocol
    private let calendar: Calendar
    private let legacyContainerURL: URL

    public init(
        store: BackupLocalStore,
        legacyProgress: any PregnancyProgressStoreProtocol,
        legacyGallery: any UltrasoundGalleryStoreProtocol,
        legacyTracking: any BellyTrackingStoreProtocol,
        calendar: Calendar,
        legacyContainerURL: URL
    ) {
        self.store = store
        self.legacyProgress = legacyProgress
        self.legacyGallery = legacyGallery
        self.legacyTracking = legacyTracking
        self.calendar = calendar
        self.legacyContainerURL = legacyContainerURL
    }

    public func execute() async throws {
        if !(await store.isInitialized()) {
            let date = try await legacyProgress.loadLastPeriodDate()
            let settings = try await legacyTracking.loadSettings()
            try await store.initializeEmpty(
                lastPeriodDay: date.map { PregnancyCalendarDay.encode($0, calendar: calendar) },
                cadenceDays: settings.intervalDays
            )
        }
        try await store.recoverPendingFiles()
        let needsMigration = try await store.needsLegacyMigration()
        let photos = try await legacyGallery.loadPhotos()
        for photo in photos where needsMigration {
            guard photo.id == URL(fileURLWithPath: photo.id).lastPathComponent else {
                throw BackupFailure.invalidData
            }
            let source = legacyContainerURL.appendingPathComponent(UltrasoundGalleryStore.directoryName)
                .appendingPathComponent(photo.id)
            let capturedAt = try source.resourceValues(forKeys: [.creationDateKey]).creationDate
            _ = try await store.addImage(
                data: photo.data, fileExtension: URL(fileURLWithPath: photo.id).pathExtension.lowercased(),
                origin: .ultrasound, sourceID: photo.id, capturedAt: capturedAt, weekNumber: nil
            )
        }
        let entries = try await legacyTracking.loadTimeline()
        for entry in entries where needsMigration {
            guard let data = try await legacyTracking.loadImageData(imageFileName: entry.imageFileName) else {
                throw BackupFailure.missingImage
            }
            _ = try await store.addImage(
                data: data, fileExtension: URL(fileURLWithPath: entry.imageFileName).pathExtension.lowercased(),
                origin: .bellyTracking, sourceID: entry.id.uuidString,
                capturedAt: entry.capturedAt, weekNumber: entry.pregnancyWeekAtCapture
            )
        }
        if needsMigration { try await store.finishLegacyMigration() }
        // Remove legacy copies only after the complete migration is durable.
        for photo in photos where try await store.containsRecord(origin: .ultrasound, sourceID: photo.id) {
            try await legacyGallery.deletePhoto(id: photo.id)
        }
        for entry in entries
            where try await store.containsRecord(origin: .bellyTracking, sourceID: entry.id.uuidString) {
            try await legacyTracking.deleteEntry(id: entry.id)
        }
        try await store.removeObsoleteFiles()
    }
}
