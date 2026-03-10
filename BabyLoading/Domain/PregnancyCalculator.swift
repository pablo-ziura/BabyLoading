import Foundation

struct PregnancyCalculator {
    /// Standard pregnancy duration is 40 weeks (280 days).
    static let standardPregnancyDurationInDays = 280

    /// Naegele's rule: Due Date = Last Period + 7 days - 3 months + 1 year
    static func calculateDueDate(lastPeriod: Date) -> Date {
        let calendar = Calendar.current
        guard let plusDays = calendar.date(byAdding: .day, value: 7, to: lastPeriod) else { return lastPeriod }
        guard let minusMonths = calendar.date(byAdding: .month, value: -3, to: plusDays) else { return plusDays }
        guard let result = calendar.date(byAdding: .year, value: 1, to: minusMonths) else { return minusMonths }
        return result
    }

    static func currentWeek(lastPeriod: Date, currentDate: Date = .now) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastPeriod), to: calendar.startOfDay(for: currentDate))

        guard let daysElapsed = components.day, daysElapsed > 0 else {
            return 0
        }

        // Medical convention:
        // 0 days - 6 days = 0 weeks (meaning "in the 1st week" but completed 0 full weeks)
        // 7 days = 1 week (meaning "start of 2nd week" or "1 week pregnant")
        return daysElapsed / 7
    }
}
