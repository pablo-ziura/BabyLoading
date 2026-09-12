import CloudBackup
import Foundation
import Testing

struct BackupPersistenceTests {
    @Test func mutationAndRecordSurviveRestartAndGuestAdoption() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = BackupLocalStore(containerURL: root)
        try await store.initializeEmpty(lastPeriodDay: "2026-01-01", cadenceDays: 14)
        let record = try await store.addImage(
            data: Data([1, 2, 3]), fileExtension: "jpg", origin: .ultrasound,
            sourceID: "legacy.jpg", capturedAt: nil, weekNumber: nil
        )
        try await store.activate(userID: "account-a", adoptGuest: true)
        let restored = BackupLocalStore(containerURL: root)
        let snapshot = try await restored.snapshot()
        #expect(snapshot.profileID == "account-a")
        #expect(snapshot.records.first?.remote.id == record.remote.id)
        #expect(snapshot.mutations.count == 3)
        #expect(snapshot.settings.lastPeriodDay == "2026-01-01")
        try await restored.activate(userID: nil, adoptGuest: false)
        #expect(try await restored.snapshot().records.isEmpty)
        try await restored.activate(userID: "account-a", adoptGuest: false)
        #expect(try await restored.snapshot().records.count == 1)
    }

    @Test func remoteDeletionOverridesPendingLocalEdit() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = BackupLocalStore(containerURL: root)
        try await store.initializeEmpty(lastPeriodDay: nil, cadenceDays: 7)
        let record = try await store.addImage(
            data: Data([1]), fileExtension: "jpg", origin: .ultrasound,
            sourceID: "photo.jpg", capturedAt: nil, weekNumber: 8
        )
        try await store.activate(userID: "account", adoptGuest: true)
        var remote = record.remote
        remote.isDeleted = true
        try await store.merge(logs: [remote], userID: "account")
        let snapshot = try await store.snapshot()
        #expect(snapshot.records.first?.remote.isDeleted == true)
        #expect(snapshot.mutations.allSatisfy { $0.payload.logID != remote.id })
    }

    @Test func calendarDayRejectsNormalizationAndPreservesDayAcrossZones() throws {
        var madrid = Calendar(identifier: .gregorian)
        madrid.timeZone = try #require(TimeZone(identifier: "Europe/Madrid"))
        var tokyo = madrid
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let day = "2026-03-29"
        let madridDate = try PregnancyCalendarDay.decode(day, calendar: madrid)
        #expect(PregnancyCalendarDay.encode(madridDate, calendar: madrid) == day)
        let tokyoDate = try PregnancyCalendarDay.decode(day, calendar: tokyo)
        #expect(PregnancyCalendarDay.encode(tokyoDate, calendar: tokyo) == day)
        #expect(throws: BackupFailure.invalidData) {
            try PregnancyCalendarDay.decode("2026-02-30", calendar: madrid)
        }
    }
}
