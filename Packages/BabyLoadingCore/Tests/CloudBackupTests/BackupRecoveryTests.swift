@testable import CloudBackup
import Foundation
import Testing

struct BackupRecoveryTests {
    @Test func restartCommitsAFileWrittenBeforeItsFinalManifestUpdate() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = BackupLocalStore(containerURL: root)
        try await store.initializeEmpty(lastPeriodDay: nil, cadenceDays: 7)
        let record = try await store.addImage(
            data: Data([1, 2, 3]), fileExtension: "jpg", origin: .ultrasound,
            sourceID: "photo.jpg", capturedAt: nil, weekNumber: nil
        )
        let manifest = root.appendingPathComponent("cloud-backup/manifest.json")
        var database = try JSONDecoder().decode(BackupDatabase.self, from: Data(contentsOf: manifest))
        let mutation = try #require(database.profiles["guest"]?.mutations.last)
        database.profiles["guest"]?.records[record.remote.id] = nil
        database.profiles["guest"]?.mutations.removeAll { $0.id == mutation.id }
        database.pendingFiles = [BackupPendingFile(profileID: "guest", record: record, mutation: mutation)]
        try JSONEncoder().encode(database).write(to: manifest, options: .atomic)
        let restarted = BackupLocalStore(containerURL: root)
        try await restarted.recoverPendingFiles()
        try await restarted.recoverPendingFiles()
        let snapshot = try await restarted.snapshot()
        #expect(snapshot.records == [record])
        #expect(snapshot.mutations.filter { $0.id == mutation.id }.count == 1)
        #expect(try await restarted.imageData(path: try #require(record.localImagePath)) == Data([1, 2, 3]))
    }

    @Test func accountSwitchRejectsAnImagePreparedForThePreviousSession() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = BackupLocalStore(containerURL: root)
        try await store.initializeEmpty(lastPeriodDay: nil, cadenceDays: 7)
        let session = await store.sessionID
        try await store.activate(userID: "another-account", adoptGuest: false)
        await #expect(throws: BackupFailure.sessionChanged) {
            try await store.addImage(
                data: Data([1]), fileExtension: "jpg", origin: .ultrasound,
                sourceID: "photo.jpg", capturedAt: nil, weekNumber: nil, expectedSession: session
            )
        }
        #expect(try await store.snapshot().records.isEmpty)
    }
}
