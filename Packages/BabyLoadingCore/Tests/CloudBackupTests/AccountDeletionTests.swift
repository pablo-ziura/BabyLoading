import CloudBackup
import Foundation
import Testing

struct AccountDeletionTests {
    @Test func localDeletionRequiresPersistedAuthenticationConfirmation() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = BackupLocalStore(containerURL: root)
        try await store.initializeEmpty(lastPeriodDay: "2026-01-01", cadenceDays: 7)
        let record = try await store.addImage(
            data: Data([1]), fileExtension: "jpg", origin: .ultrasound,
            sourceID: "photo.jpg", capturedAt: nil, weekNumber: nil
        )
        let path = try #require(record.localImagePath)
        try await store.activate(userID: "account", adoptGuest: true)
        try await store.beginAccountDeletion(userID: "account")
        await #expect(throws: BackupFailure.sessionChanged) {
            try await store.finishAccountDeletion(userID: "account")
        }
        #expect(try await store.imageData(path: path) == Data([1]))
        try await store.confirmAccountDeletion(userID: "account")
        let restarted = BackupLocalStore(containerURL: root)
        let previousSession = await restarted.sessionID
        #expect(try await restarted.snapshot().confirmedAccountDeletion == "account")
        try await restarted.finishAccountDeletion(userID: "account")
        #expect(await restarted.sessionID != previousSession)
        #expect(try await restarted.snapshot().profileID == "guest")
        await #expect(throws: BackupFailure.missingImage) { try await restarted.imageData(path: path) }
    }

    @Test func cancelledAuthenticationDeletionPreservesAccount() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = BackupLocalStore(containerURL: root)
        try await store.initializeEmpty(lastPeriodDay: "2026-01-01", cadenceDays: 7)
        try await store.activate(userID: "account", adoptGuest: true)
        try await store.beginAccountDeletion(userID: "account")
        try await store.cancelAccountDeletion()
        let snapshot = try await store.snapshot()
        #expect(snapshot.pendingAccountDeletion == nil)
        #expect(snapshot.confirmedAccountDeletion == nil)
        #expect(snapshot.settings.lastPeriodDay == "2026-01-01")
    }
}
