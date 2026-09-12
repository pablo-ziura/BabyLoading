import CloudBackup
import Foundation
import Testing

struct ImageUploadServiceTests {
    @Test func retriesDocumentConfirmationWithoutUploadingAgain() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let local = BackupLocalStore(containerURL: root)
        try await local.initializeEmpty(lastPeriodDay: nil, cadenceDays: 7)
        _ = try await local.addImage(
            data: Data([1]), fileExtension: "jpg", origin: .ultrasound,
            sourceID: "photo.jpg", capturedAt: nil, weekNumber: nil
        )
        try await local.activate(userID: "account", adoptGuest: true)
        let remote = ImageConfirmationRemoteStore()
        let storage = RecordingImageStorage()
        let engine = ImageUploadService(
            localStore: local, storage: storage, preparer: CopyImagePreparer(),
            synchronize: SynchronizeBackupUseCase(localStore: local, remoteStore: remote),
            temporaryDirectory: root.appendingPathComponent("temporary")
        )
        let account = BackupAccount(
            id: "account", email: nil, isAnonymous: false, providers: [], isEmailVerified: false
        )
        await #expect(throws: BackupFailure.network) { try await engine.execute(account: account) }
        #expect(await storage.uploadCount == 1)
        #expect(try await local.snapshot().records.first?.syncStatus == .pending)
        try await engine.execute(account: account)
        #expect(await storage.uploadCount == 1)
        #expect(try await local.snapshot().records.first?.syncStatus == .synced)
    }

    @Test func interruptedUploadReturnsToPendingWhenAccountIsActivated() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let local = BackupLocalStore(containerURL: root)
        try await local.initializeEmpty(lastPeriodDay: nil, cadenceDays: 7)
        let record = try await local.addImage(
            data: Data([1]), fileExtension: "jpg", origin: .ultrasound,
            sourceID: "photo.jpg", capturedAt: nil, weekNumber: nil
        )
        try await local.activate(userID: "account", adoptGuest: true)
        try await local.markUploading(logID: record.remote.id, userID: "account")
        let restarted = BackupLocalStore(containerURL: root)
        try await restarted.activate(userID: "account", adoptGuest: false)
        #expect(try await restarted.snapshot().records.first?.syncStatus == .pending)
    }
}

private struct CopyImagePreparer: BackupImagePreparingProtocol {
    func prepareJPEG(from source: URL, to destination: URL) throws {
        try FileManager.default.copyItem(at: source, to: destination)
    }
    func validateDownloadedJPEG(at url: URL) {}
}

private actor RecordingImageStorage: BackupImageStorageProtocol {
    var uploadCount = 0
    func upload(fileURL: URL, userID: String, logID: String) -> String {
        uploadCount += 1
        return "https://example.com/photo.jpg"
    }
    func download(to fileURL: URL, userID: String, logID: String) throws { try Data([1]).write(to: fileURL) }
    func delete(userID: String, logID: String) {}
    func cancelAll() {}
}

private actor ImageConfirmationRemoteStore: BackupRemoteStoreProtocol {
    private var shouldFail = true
    func apply(_ mutation: BackupMutation, userID: String) throws {
        if case .image = mutation.payload, shouldFail {
            shouldFail = false
            throw BackupFailure.network
        }
    }
    func fetch(userID: String) -> [BackupRemoteEvent] { [] }
    func observe(userID: String) -> AsyncThrowingStream<BackupRemoteEvent, Error> {
        AsyncThrowingStream { $0.finish() }
    }
    func reset() {}
}
