import Foundation

public struct PregnancyProgress: Equatable, Sendable {
    public let lastPeriodDate: Date
    public let dueDate: Date
    public let currentWeek: Int
    public let daysUntilDueDate: Int

    public init(
        lastPeriodDate: Date,
        dueDate: Date,
        currentWeek: Int,
        daysUntilDueDate: Int
    ) {
        self.lastPeriodDate = lastPeriodDate
        self.dueDate = dueDate
        self.currentWeek = currentWeek
        self.daysUntilDueDate = daysUntilDueDate
    }
}
