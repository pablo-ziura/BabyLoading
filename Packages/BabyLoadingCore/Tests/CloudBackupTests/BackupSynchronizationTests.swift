import CloudBackup
import Foundation
import Testing

struct BackupSynchronizationTests {
    @Test func deletingAnUnpublishedPhotoRetainsItsIdentityForTheRemoteTombstone() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = BackupLocalStore(containerURL: root)
        try await store.initializeEmpty(lastPeriodDay: nil, cadenceDays: 7)
        let record = try await store.addImage(
            data: Data([1]), fileExtension: "jpg", origin: .ultrasound,
            sourceID: "historical photo.jpg", capturedAt: nil, weekNumber: nil
        )
        try await store.activate(userID: "account", adoptGuest: true)
        try await store.deleteImage(origin: .ultrasound, sourceID: record.remote.sourceID)
        let mutations = try await store.snapshot().mutations.filter { $0.payload.logID == record.remote.id }
        #expect(mutations.count == 1)
        guard case let .create(tombstone) = mutations.first?.payload else {
            Issue.record("An unpublished deletion must carry the original identity")
            return
        }
        #expect(tombstone.isDeleted)
        #expect(tombstone.sourceID == record.remote.sourceID)
    }

    @Test func uploadedURLSurvivesRestartUntilDocumentAcknowledgement() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = BackupLocalStore(containerURL: root)
        try await store.initializeEmpty(lastPeriodDay: nil, cadenceDays: 7)
        let record = try await store.addImage(
            data: Data([1]), fileExtension: "jpg", origin: .ultrasound,
            sourceID: "photo.jpg", capturedAt: nil, weekNumber: nil
        )
        try await store.activate(userID: "account", adoptGuest: true)
        for mutation in try await store.snapshot().mutations {
            try await store.acknowledge(mutation, userID: "account")
        }
        try await store.markUploading(logID: record.remote.id, userID: "account")
        try await store.recordUploadedImage(
            logID: record.remote.id, url: "https://example.com/photo", userID: "account"
        )
        let restarted = BackupLocalStore(containerURL: root)
        let snapshot = try await restarted.snapshot()
        #expect(snapshot.records.first?.remote.remoteImageUrl == "https://example.com/photo")
        #expect(snapshot.records.first?.syncStatus == .pending)
        try await restarted.acknowledge(try #require(snapshot.mutations.first), userID: "account")
        #expect(try await restarted.snapshot().records.first?.syncStatus == .synced)
    }
}
