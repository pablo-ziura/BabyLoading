import Foundation

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
