import CloudBackup
import Foundation
import Testing

struct SynchronizeBackupUseCaseTests {
    @Test func anonymousAccountsNeverReachTheRemoteStore() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let local = BackupLocalStore(containerURL: root)
        let remote = RecordingBackupRemoteStore()
        try await local.initializeEmpty(lastPeriodDay: "2026-01-01", cadenceDays: 7)
        let operation = SynchronizeBackupUseCase(localStore: local, remoteStore: remote)
        let anonymous = BackupAccount(
            id: "anonymous", email: nil, isAnonymous: true, providers: [], isEmailVerified: false
        )
        try await operation.execute(account: anonymous)
        try await operation.refresh(account: anonymous)
        #expect(await remote.requestCount == 0)
        #expect(try await local.snapshot().mutations.count == 2)
    }

    @Test func aFailedServerConfirmationKeepsTheSameOperationIdentityForRetry() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let local = BackupLocalStore(containerURL: root)
        let remote = RecordingBackupRemoteStore()
        try await local.initializeEmpty(lastPeriodDay: "2026-01-01", cadenceDays: 7)
        try await local.activate(userID: "account", adoptGuest: true)
        let operation = SynchronizeBackupUseCase(localStore: local, remoteStore: remote)
        let account = BackupAccount(
            id: "account", email: nil, isAnonymous: false, providers: [], isEmailVerified: false
        )
        let original = try await local.snapshot().mutations.map(\.id)
        await remote.failNextConfirmation()
        await #expect(throws: BackupFailure.network) { try await operation.execute(account: account) }
        #expect(try await local.snapshot().mutations.map(\.id) == original)
        try await operation.execute(account: account)
        #expect(try await local.snapshot().mutations.isEmpty)
        #expect(await remote.appliedIDs == Set(original))
        #expect(await remote.requestCount == 4)
    }
}

private actor RecordingBackupRemoteStore: BackupRemoteStoreProtocol {
    var requestCount = 0
    var appliedIDs: Set<String> = []
    private var shouldFailConfirmation = false

    func failNextConfirmation() { shouldFailConfirmation = true }
    func apply(_ mutation: BackupMutation, userID: String) throws {
        requestCount += 1
        appliedIDs.insert(mutation.id)
        if shouldFailConfirmation {
            shouldFailConfirmation = false
            throw BackupFailure.network
        }
    }
    func fetch(userID: String) -> [BackupRemoteEvent] { requestCount += 1; return [] }
    func observe(userID: String) -> AsyncThrowingStream<BackupRemoteEvent, Error> {
        AsyncThrowingStream { $0.finish() }
    }
    func reset() {}
}
