import Foundation

public enum PregnancyCalendarDay {
    public static func encode(_ date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    public static func decode(_ value: String, calendar: Calendar) throws -> Date {
        let parts = value.split(separator: "-", omittingEmptySubsequences: false)
        guard value.count == 10, parts.count == 3,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]),
              let date = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)),
              encode(date, calendar: calendar) == value else {
            throw BackupFailure.invalidData
        }
        return date
    }
}
