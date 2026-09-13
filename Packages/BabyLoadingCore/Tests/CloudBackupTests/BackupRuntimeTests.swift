import BellyTracking
import CloudBackup
import Foundation
import PregnancyProgress
import Testing
import UltrasoundGallery

@MainActor
struct BackupRuntimeTests {
    @Test func firstOfflineLaunchLoadsGuestDataWithoutRemoteRequests() async throws {
        let fixture = try await RuntimeFixture()
        defer { fixture.removeFiles() }
        try await fixture.runtime.initialize()
        #expect(fixture.runtime.state.isReady)
        #expect(fixture.runtime.state.isGuest)
        #expect(fixture.runtime.state.records.count == 1)
        #expect(await fixture.remote.requestCount == 0)
    }

    @Test func registrationAdoptsGuestDataWithStableUIDAndSignOutIsolatesIt() async throws {
        let fixture = try await RuntimeFixture()
        defer { fixture.removeFiles() }
        try await fixture.runtime.initialize()
        try await fixture.runtime.register(email: "parent@example.com", password: "password")
        #expect(fixture.runtime.state.account?.id == "anonymous-id")
        #expect(fixture.runtime.state.records.count == 1)
        #expect(!fixture.runtime.state.hasGuestData)
        try await fixture.runtime.signOut()
        #expect(fixture.runtime.state.profileID == "guest")
        #expect(fixture.runtime.state.records.isEmpty)
        #expect(await fixture.projection.loadLastPeriodDate() == nil)
        try await fixture.local.activate(userID: "anonymous-id", adoptGuest: false)
        #expect(try await fixture.local.snapshot().records.count == 1)
    }

    @Test func existingAccountOffersImportAndKeepsRemoteDateAndCadence() async throws {
        let fixture = try await RuntimeFixture()
        defer { fixture.removeFiles() }
        try await fixture.runtime.initialize()
        try await fixture.runtime.signIn(email: "parent@example.com", password: "password")
        #expect(fixture.runtime.state.hasGuestData)
        #expect(fixture.runtime.state.records.isEmpty)
        try await fixture.runtime.importGuest()
        try await fixture.runtime.importGuest()
        let snapshot = try await fixture.local.snapshot()
        #expect(snapshot.records.count == 1)
        #expect(snapshot.settings.lastPeriodDay == "2026-02-02")
        #expect(snapshot.settings.cadenceDays == 28)
    }

    @Test func expiredAuthenticationReauthenticatesBeforeLocalDeletion() async throws {
        let fixture = try await RuntimeFixture()
        defer { fixture.removeFiles() }
        try await fixture.runtime.initialize()
        try await fixture.runtime.register(email: "parent@example.com", password: "password")
        fixture.authentication.requiresRecentLogin = true
        await #expect(throws: BackupFailure.credentials) { try await fixture.runtime.deleteAccount(password: "") }
        #expect(fixture.runtime.state.records.count == 1)
        try await fixture.runtime.deleteAccount(password: "password")
        #expect(fixture.runtime.state.isGuest)
        #expect(fixture.runtime.state.records.isEmpty)
        #expect(try await fixture.local.snapshot().pendingAccountDeletion == nil)
    }

    @Test func restartRecoversLinkBeforeGuestAdoptionWasCommitted() async throws {
        let fixture = try await RuntimeFixture()
        defer { fixture.removeFiles() }
        try await fixture.local.beginGuestLink(userID: "anonymous-id")
        try await fixture.authentication.signInAnonymously()
        try await fixture.authentication.linkEmail(email: "parent@example.com", password: "password")
        try await fixture.runtime.initialize()
        #expect(fixture.runtime.state.profileID == "anonymous-id")
        #expect(fixture.runtime.state.records.count == 1)
        #expect(!fixture.runtime.state.hasGuestData)
    }
}

@MainActor
private final class RuntimeFixture {
    let root: URL
    let local: BackupLocalStore
    let remote = RuntimeRemoteStore()
    let authentication = RuntimeAuthentication()
    let projection = RuntimeProjectionStore()
    let runtime: BackupRuntime

    init() async throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        local = BackupLocalStore(containerURL: root)
        try await local.initializeEmpty(lastPeriodDay: "2026-01-01", cadenceDays: 14)
        try await local.finishLegacyMigration()
        _ = try await local.addImage(
            data: Data([1]), fileExtension: "jpg", origin: .ultrasound,
            sourceID: "photo.jpg", capturedAt: nil, weekNumber: nil
        )
        let synchronize = SynchronizeBackupUseCase(localStore: local, remoteStore: remote)
        let images = ImageUploadService(
            localStore: local, storage: RuntimeStorage(), preparer: RuntimeImagePreparer(),
            synchronize: synchronize, temporaryDirectory: root.appendingPathComponent("temporary")
        )
        let driver = BackupSynchronizationDriver(
            localStore: local, remoteStore: remote, connectivity: OfflineConnectivity(),
            images: images, synchronize: synchronize
        )
        let services = BackupServices(authentication: authentication, remoteStore: remote, driver: driver)
        runtime = BackupRuntime(
            localStore: local,
            initializeLocal: InitializeBackupUseCase(
                store: local, legacyProgress: projection, legacyGallery: UltrasoundGalleryStore(containerURL: root),
                legacyTracking: BellyTrackingStore(containerURL: root),
                calendar: Calendar(identifier: .gregorian), legacyContainerURL: root
            ),
            projectionStore: projection, calendar: Calendar(identifier: .gregorian), makeServices: { services }
        )
    }
    func removeFiles() { try? FileManager.default.removeItem(at: root) }
}

@MainActor
private final class RuntimeAuthentication: BackupAuthenticationProtocol {
    var currentAccount: BackupAccount?
    var requiresRecentLogin = false
    func observeAccounts() -> AsyncStream<BackupAccount?> { AsyncStream { $0.finish() } }
    func signInAnonymously() {
        currentAccount = BackupAccount(
            id: "anonymous-id", email: nil, isAnonymous: true, providers: [], isEmailVerified: false
        )
    }
    func linkEmail(email: String, password: String) throws {
        let id = try #require(currentAccount?.id)
        currentAccount = account(id: id, email: email)
    }
    func signInEmail(email: String, password: String) { currentAccount = account(id: "existing", email: email) }
    func signInGoogle(linkAnonymous: Bool) { currentAccount = account(id: "existing", email: "parent@example.com") }
    func resetPassword(email: String) {}
    func sendVerification() {}
    func reauthenticate(password: String) throws {
        guard password == "password" else { throw BackupFailure.credentials }
        requiresRecentLogin = false
    }
    func signOut() { currentAccount = nil }
    func deleteAccount() throws {
        if requiresRecentLogin { throw BackupFailure.recentLoginRequired }
        currentAccount = nil
    }
    private func account(id: String, email: String) -> BackupAccount {
        BackupAccount(id: id, email: email, isAnonymous: false, providers: ["password"], isEmailVerified: false)
    }
}

private actor RuntimeProjectionStore: PregnancyProgressStoreProtocol {
    private var date: Date?
    func loadLastPeriodDate() -> Date? { date }
    func updateLastPeriodDate(_ date: Date?) { self.date = date }
}

private actor RuntimeRemoteStore: BackupRemoteStoreProtocol {
    var requestCount = 0
    func apply(_ mutation: BackupMutation, userID: String) { requestCount += 1 }
    func fetch(userID: String) -> [BackupRemoteEvent] {
        requestCount += 1
        return [.settings(RemotePregnancySettings(lastPeriodDay: "2026-02-02", cadenceDays: 28))]
    }
    func observe(userID: String) -> AsyncThrowingStream<BackupRemoteEvent, Error> {
        requestCount += 1
        return AsyncThrowingStream { $0.finish() }
    }
    func reset() {}
}

private struct RuntimeStorage: BackupImageStorageProtocol {
    func upload(fileURL: URL, userID: String, logID: String) throws -> String { throw BackupFailure.network }
    func download(to fileURL: URL, userID: String, logID: String) throws { throw BackupFailure.network }
    func delete(userID: String, logID: String) throws { throw BackupFailure.network }
    func cancelAll() {}
}

private struct RuntimeImagePreparer: BackupImagePreparingProtocol {
    func prepareJPEG(from source: URL, to destination: URL) {}
    func validateDownloadedJPEG(at url: URL) {}
}

private struct OfflineConnectivity: BackupConnectivityProtocol {
    func changes() -> AsyncStream<Bool> { AsyncStream { $0.yield(false); $0.finish() } }
}
