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

public enum PregnancyCalculator {
    public static let standardPregnancyDurationInDays = 280

    public static func calculateDueDate(
        lastPeriod: Date,
        calendar: Calendar = .current
    ) -> Date {
        guard let plusDays = calendar.date(byAdding: .day, value: 7, to: lastPeriod) else {
            return lastPeriod
        }
        guard let minusMonths = calendar.date(byAdding: .month, value: -3, to: plusDays) else {
            return plusDays
        }
        guard let result = calendar.date(byAdding: .year, value: 1, to: minusMonths) else {
            return minusMonths
        }

        return result
    }

    public static func currentWeek(
        lastPeriod: Date,
        currentDate: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        let components = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: lastPeriod),
            to: calendar.startOfDay(for: currentDate)
        )

        guard let daysElapsed = components.day, daysElapsed > 0 else {
            return 0
        }

        return daysElapsed / 7
    }

    public static func daysUntilDueDate(
        lastPeriod: Date,
        asOf date: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        let dueDate = calculateDueDate(lastPeriod: lastPeriod, calendar: calendar)
        let components = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: date),
            to: calendar.startOfDay(for: dueDate)
        )

        return max(0, components.day ?? 0)
    }
}
