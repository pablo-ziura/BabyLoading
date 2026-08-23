import Foundation

public struct BellyTrackingEntry: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let imageFileName: String
    public let capturedAt: Date
    public let pregnancyWeekAtCapture: Int?

    public init(
        id: UUID = UUID(),
        imageFileName: String,
        capturedAt: Date = .now,
        pregnancyWeekAtCapture: Int?
    ) {
        self.id = id
        self.imageFileName = imageFileName
        self.capturedAt = capturedAt
        self.pregnancyWeekAtCapture = pregnancyWeekAtCapture
    }
}

public struct BellyTrackingSettings: Codable, Equatable, Sendable {
    public static let supportedIntervals = [7, 14, 28]
    public static let defaultIntervalDays = 7
    public static let `default` = BellyTrackingSettings()

    public let intervalDays: Int

    public init(intervalDays: Int = BellyTrackingSettings.defaultIntervalDays) {
        self.intervalDays = Self.supportedIntervals.contains(intervalDays)
            ? intervalDays
            : Self.defaultIntervalDays
    }

    func trackingStatus(
        lastCapture: Date?,
        asOf date: Date,
        calendar: Calendar = .current
    ) -> BellyTrackingStatus {
        guard let lastCapture else {
            return .needsInitialCapture
        }

        let captureDay = calendar.startOfDay(for: lastCapture)
        let currentDay = calendar.startOfDay(for: date)
        let elapsedDays = max(
            0,
            calendar.dateComponents([.day], from: captureDay, to: currentDay).day ?? 0
        )
        let nextDueDate = calendar.date(
            byAdding: .day,
            value: intervalDays,
            to: captureDay
        ) ?? captureDay

        if elapsedDays <= intervalDays {
            return .upToDate(nextDueDate: nextDueDate)
        }

        return .pending(nextDueDate: nextDueDate)
    }
}

public enum BellyTrackingStatus: Equatable, Sendable {
    case needsInitialCapture
    case upToDate(nextDueDate: Date)
    case pending(nextDueDate: Date)
}

struct BellyTrackingManifest: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1
    static let empty = BellyTrackingManifest(
        schemaVersion: currentSchemaVersion,
        settings: .default,
        entries: []
    )

    let schemaVersion: Int
    var settings: BellyTrackingSettings
    var entries: [BellyTrackingEntry]
}

public enum BellyTrackingStoreError: Error, Equatable, Sendable {
    case unsupportedImageFormat
    case imageProcessingFailed
    case invalidTrackingDirectory
    case invalidManifestFile
    case invalidImageFileName(String)
    case duplicateEntryIdentifier(UUID)
    case duplicateImageFileName(String)
    case unsupportedManifestSchema(Int)
    case rollbackFailed(operation: String, rollback: String)
}
