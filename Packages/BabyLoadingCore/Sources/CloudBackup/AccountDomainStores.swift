import BellyTracking
import Foundation
import PregnancyProgress
import UltrasoundGallery

public struct AccountPregnancyProgressStore: PregnancyProgressStoreProtocol {
    private let store: BackupLocalStore
    private let calendar: Calendar

    public init(store: BackupLocalStore, calendar: Calendar) {
        self.store = store
        self.calendar = calendar
    }

    public func loadLastPeriodDate() async throws -> Date? {
        try await store.snapshot().settings.lastPeriodDay.map {
            try PregnancyCalendarDay.decode($0, calendar: calendar)
        }
    }

    public func updateLastPeriodDate(_ date: Date?) async throws {
        try await store.setLastPeriodDay(date.map { PregnancyCalendarDay.encode($0, calendar: calendar) })
    }
}

public struct AccountUltrasoundStore: UltrasoundGalleryStoreProtocol {
    private let store: BackupLocalStore

    public init(store: BackupLocalStore) { self.store = store }

    public func loadPhotos() async throws -> [UltrasoundPhoto] {
        let session = await store.sessionID
        let snapshot = try await store.snapshot()
        var result: [UltrasoundPhoto] = []
        for record in snapshot.records.sorted(by: {
            let first = $0.remote.capturedAt ?? .distantPast
            let second = $1.remote.capturedAt ?? .distantPast
            return first == second ? $0.remote.sourceID < $1.remote.sourceID : first < second
        })
            where record.remote.origin == .ultrasound && !record.remote.isDeleted {
            if let path = record.localImagePath {
                let data = try await store.imageData(path: path, expectedSession: session)
                result.append(UltrasoundPhoto(id: record.remote.sourceID, data: data))
            }
        }
        guard await store.sessionID == session else { throw BackupFailure.sessionChanged }
        return result
    }

    public func addPhoto(image: ValidatedUltrasoundImage) async throws -> UltrasoundPhoto {
        let id = "\(UUID().uuidString).\(image.format.fileExtension)"
        _ = try await store.addImage(
            data: image.data, fileExtension: image.format.fileExtension, origin: .ultrasound,
            sourceID: id, capturedAt: .now, weekNumber: nil
        )
        return UltrasoundPhoto(id: id, data: image.data)
    }

    public func deletePhoto(id: String) async throws {
        try await store.deleteImage(origin: .ultrasound, sourceID: id)
    }
}

public struct AccountBellyTrackingStore: BellyTrackingStoreProtocol {
    private let store: BackupLocalStore

    public init(store: BackupLocalStore) { self.store = store }

    public func loadTimeline() async throws -> [BellyTrackingEntry] {
        try await store.snapshot().records.compactMap { record in
            guard record.remote.origin == .bellyTracking, !record.remote.isDeleted,
                  let path = record.localImagePath, let id = UUID(uuidString: record.remote.sourceID),
                  let date = record.remote.capturedAt else { return nil }
            return BellyTrackingEntry(
                id: id, imageFileName: path, capturedAt: date, pregnancyWeekAtCapture: record.remote.weekNumber
            )
        }.sorted { $0.capturedAt < $1.capturedAt }
    }

    public func loadImageData(imageFileName: String) async throws -> Data? {
        let session = await store.sessionID
        let records = try await store.snapshot().records
        guard records.contains(where: { !$0.remote.isDeleted && $0.localImagePath == imageFileName }) else {
            return nil
        }
        return try await store.imageData(path: imageFileName, expectedSession: session)
    }

    public func capturePhoto(
        data: Data, capturedAt: Date, pregnancyWeekAtCapture: Int?
    ) async throws -> BellyTrackingEntry {
        let session = await store.sessionID
        let prepared = try BellyTrackingImageProcessor.prepareForStorage(data)
        let id = UUID()
        let record = try await store.addImage(
            data: prepared.data, fileExtension: prepared.fileExtension, origin: .bellyTracking,
            sourceID: id.uuidString, capturedAt: capturedAt,
            weekNumber: pregnancyWeekAtCapture, expectedSession: session
        )
        guard let path = record.localImagePath else { throw BackupFailure.missingImage }
        return BellyTrackingEntry(
            id: id, imageFileName: path, capturedAt: capturedAt, pregnancyWeekAtCapture: pregnancyWeekAtCapture
        )
    }

    public func deleteEntry(id: UUID) async throws {
        try await store.deleteImage(origin: .bellyTracking, sourceID: id.uuidString)
    }

    public func loadSettings() async throws -> BellyTrackingSettings {
        try await BellyTrackingSettings(intervalDays: store.snapshot().settings.cadenceDays ?? 7)
    }

    public func updateSettings(_ settings: BellyTrackingSettings) async throws {
        try await store.setCadence(settings.intervalDays)
    }
}
