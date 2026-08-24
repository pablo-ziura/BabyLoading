@testable import BellyTracking
import Foundation
import Testing

struct BellyTrackingCadenceTests {
    @Test func supportsWeeklyBiweeklyAndFourWeeklyCadences() {
        #expect(BellyTrackingSettings.supportedIntervals == [7, 14, 28])
        #expect(BellyTrackingSettings(intervalDays: 14).intervalDays == 14)
        #expect(
            BellyTrackingSettings(intervalDays: 10).intervalDays
                == BellyTrackingSettings.defaultIntervalDays
        )
    }

    @Test func requiresAnInitialCaptureWhenTheTimelineIsEmpty() throws {
        let date = try BellyTrackingTestSupport.date("2026-08-20T08:00:00Z")

        let status = BellyTrackingSettings.default.trackingStatus(
            lastCapture: nil,
            asOf: date,
            calendar: utcCalendar
        )

        #expect(status == .needsInitialCapture)
    }

    @Test func keepsTheExactCadenceDayUpToDate() throws {
        let captureDate = try BellyTrackingTestSupport.date("2026-08-13T23:30:00Z")
        let cadenceDate = try BellyTrackingTestSupport.date("2026-08-20T00:15:00Z")
        let expectedDueDate = try BellyTrackingTestSupport.date("2026-08-20T00:00:00Z")

        let status = BellyTrackingSettings(intervalDays: 7).trackingStatus(
            lastCapture: captureDate,
            asOf: cadenceDate,
            calendar: utcCalendar
        )

        #expect(status == .upToDate(nextDueDate: expectedDueDate))
    }

    @Test func becomesPendingOnlyAfterTheCadenceDay() throws {
        let captureDate = try BellyTrackingTestSupport.date("2026-08-13T08:00:00Z")
        let overdueDate = try BellyTrackingTestSupport.date("2026-08-21T08:00:00Z")
        let expectedDueDate = try BellyTrackingTestSupport.date("2026-08-20T00:00:00Z")

        let status = BellyTrackingSettings(intervalDays: 7).trackingStatus(
            lastCapture: captureDate,
            asOf: overdueDate,
            calendar: utcCalendar
        )

        #expect(status == .pending(nextDueDate: expectedDueDate))
    }

    @Test func supportsTheFourWeeklyCadenceBoundary() throws {
        let captureDate = try BellyTrackingTestSupport.date("2026-08-01T08:00:00Z")
        let cadenceDate = try BellyTrackingTestSupport.date("2026-08-29T23:59:00Z")
        let overdueDate = try BellyTrackingTestSupport.date("2026-08-30T08:00:00Z")
        let expectedDueDate = try BellyTrackingTestSupport.date("2026-08-29T00:00:00Z")
        let settings = BellyTrackingSettings(intervalDays: 28)

        #expect(
            settings.trackingStatus(
                lastCapture: captureDate,
                asOf: cadenceDate,
                calendar: utcCalendar
            ) == .upToDate(nextDueDate: expectedDueDate)
        )
        #expect(
            settings.trackingStatus(
                lastCapture: captureDate,
                asOf: overdueDate,
                calendar: utcCalendar
            ) == .pending(nextDueDate: expectedDueDate)
        )
    }

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
        return calendar
    }
}
