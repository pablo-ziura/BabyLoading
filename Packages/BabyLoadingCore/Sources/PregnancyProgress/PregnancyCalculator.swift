import Foundation

public enum PregnancyCalculator {
    public static let standardPregnancyDurationInDays = 280
    public static let lateTermStartInDays = 41 * 7
    public static let postTermStartInDays = 42 * 7

    public static func calculateDueDate(
        lastPeriod: Date,
        calendar: Calendar = .current
    ) -> Date {
        let startOfLastPeriod = calendar.startOfDay(for: lastPeriod)
        return calendar.date(
            byAdding: .day,
            value: standardPregnancyDurationInDays,
            to: startOfLastPeriod
        ) ?? startOfLastPeriod
    }

    public static func gestationalAge(
        lastPeriod: Date,
        asOf date: Date = .now,
        calendar: Calendar = .current
    ) -> GestationalAge {
        let elapsedDays = max(0, calendarDayDifference(
            from: lastPeriod,
            to: date,
            calendar: calendar
        ))

        return GestationalAge(
            weeks: elapsedDays / 7,
            days: elapsedDays % 7
        )
    }

    public static func dueDateRelation(
        dueDate: Date,
        asOf date: Date = .now,
        calendar: Calendar = .current
    ) -> DueDateRelation {
        let dayDifference = calendarDayDifference(
            from: date,
            to: dueDate,
            calendar: calendar
        )

        switch dayDifference {
        case let days where days > 0:
            return .upcoming(days: days)
        case 0:
            return .today
        default:
            return .elapsed(days: abs(dayDifference))
        }
    }

    public static func phase(for gestationalAge: GestationalAge) -> PregnancyPhase {
        let elapsedDays = gestationalAge.weeks * 7 + gestationalAge.days

        switch elapsedDays {
        case postTermStartInDays...:
            return .postTerm
        case lateTermStartInDays...:
            return .lateTerm
        default:
            return .ongoing
        }
    }

    public static func isFuture(
        lastPeriod: Date,
        asOf date: Date,
        calendar: Calendar = .current
    ) -> Bool {
        calendarDayDifference(from: date, to: lastPeriod, calendar: calendar) > 0
    }

    private static func calendarDayDifference(
        from startDate: Date,
        to endDate: Date,
        calendar: Calendar
    ) -> Int {
        calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: startDate),
            to: calendar.startOfDay(for: endDate)
        ).day ?? 0
    }
}
