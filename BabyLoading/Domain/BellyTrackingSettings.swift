import Foundation

struct BellyTrackingSettings: Codable, Equatable, Sendable {
    static let supportedIntervals = [7, 14, 28]
    static let defaultIntervalDays = 7
    static let `default` = BellyTrackingSettings()

    var intervalDays: Int

    init(intervalDays: Int = BellyTrackingSettings.defaultIntervalDays) {
        if BellyTrackingSettings.supportedIntervals.contains(intervalDays) {
            self.intervalDays = intervalDays
        } else {
            self.intervalDays = BellyTrackingSettings.defaultIntervalDays
        }
    }
}

enum BellyTrackingStatus: Equatable, Sendable {
    case needsInitialCapture
    case upToDate(nextDueDate: Date)
    case pending(nextDueDate: Date)
}

extension BellyTrackingSettings {
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
        let nextDueDate = calendar.date(byAdding: .day, value: intervalDays, to: captureDay) ?? captureDay

        if elapsedDays <= intervalDays {
            return .upToDate(nextDueDate: nextDueDate)
        }

        return .pending(nextDueDate: nextDueDate)
    }
}
