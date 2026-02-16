import Foundation

struct PregnancyCalculator {
    /// Standard pregnancy duration is 40 weeks (280 days).
    static let standardPregnancyDurationInDays = 280

    static func currentWeek(dueDate: Date, currentDate: Date = .now) -> Int {
        let calendar = Calendar.current

        // Calculate the conception date (approximate)
        guard let conceptionDate = calendar.date(byAdding: .day, value: -standardPregnancyDurationInDays, to: dueDate) else {
            return 0
        }

        // Calculate days elapsed since conception
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: conceptionDate), to: calendar.startOfDay(for: currentDate))

        guard let daysElapsed = components.day, daysElapsed > 0 else {
            return 0
        }

        // Week calculation: (days / 7) + 1
        return (daysElapsed / 7) + 1
    }

    static func babySize(for dueDate: Date, currentDate: Date = .now) -> BabySize {
        let week = currentWeek(dueDate: dueDate, currentDate: currentDate)
        return BabySize.from(week: week)
    }
}
