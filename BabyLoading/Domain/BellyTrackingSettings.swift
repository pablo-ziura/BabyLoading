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
