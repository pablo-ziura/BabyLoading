@testable import BabyLoading
import Foundation
import Testing

struct BellyTrackingStatusTests {
    private let calendar: Calendar

    init() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        self.calendar = calendar
    }

    @Test func noCaptureIsPendingInitialCapture() throws {
        let status = BellyTrackingSettings(intervalDays: 7).trackingStatus(
            lastCapture: nil,
            asOf: try date("2026-08-20"),
            calendar: calendar
        )

        #expect(status == .needsInitialCapture)
    }

    @Test func captureAtCadenceLimitIsStillUpToDate() throws {
        let captureDate = try date("2026-08-13")
        let currentDate = try date("2026-08-20")

        let status = BellyTrackingSettings(intervalDays: 7).trackingStatus(
            lastCapture: captureDate,
            asOf: currentDate,
            calendar: calendar
        )

        #expect(status == .upToDate(nextDueDate: currentDate))
    }

    @Test func capturePastCadenceIsPending() throws {
        let captureDate = try date("2026-08-12")
        let currentDate = try date("2026-08-20")
        let dueDate = try date("2026-08-19")

        let status = BellyTrackingSettings(intervalDays: 7).trackingStatus(
            lastCapture: captureDate,
            asOf: currentDate,
            calendar: calendar
        )

        #expect(status == .pending(nextDueDate: dueDate))
    }

    @Test func twentyEightDayCadenceKeepsTheSameCaptureUpToDate() throws {
        let captureDate = try date("2026-08-10")
        let currentDate = try date("2026-08-20")
        let dueDate = try date("2026-09-07")

        let status = BellyTrackingSettings(intervalDays: 28).trackingStatus(
            lastCapture: captureDate,
            asOf: currentDate,
            calendar: calendar
        )

        #expect(status == .upToDate(nextDueDate: dueDate))
    }

    private func date(_ string: String) throws -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return try #require(formatter.date(from: string))
    }
}
