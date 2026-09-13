import Foundation

public struct BackupState: Equatable, Sendable {
    public var account: BackupAccount?
    public var profileID = "guest"
    public var isWorking = false
    public var isReady = false
    public var hasGuestData = false
    public var failure: BackupFailure?
    public var records: [BackupRecord] = []
    public var lastPeriodDay: String?

    public init() {}
    public var isGuest: Bool { account?.isAnonymous != false }
}

@MainActor
public protocol BackupAccountOperationsProtocol: AnyObject, Sendable {
    func register(email: String, password: String) async throws
    func signIn(email: String, password: String) async throws
    func signInGoogle() async throws
    func resetPassword(email: String) async throws
    func sendVerification() async throws
    func signOut() async throws
    func deleteAccount(password: String) async throws
    func importGuest() async throws
    func retry() async throws
    func observeState() -> AsyncStream<BackupState>
}

@MainActor
public struct BackupServices {
    public let authentication: any BackupAuthenticationProtocol
    public let remoteStore: any BackupRemoteStoreProtocol
    public let driver: BackupSynchronizationDriver

    public init(
        authentication: any BackupAuthenticationProtocol,
        remoteStore: any BackupRemoteStoreProtocol,
        driver: BackupSynchronizationDriver
    ) {
        self.authentication = authentication
        self.remoteStore = remoteStore
        self.driver = driver
    }
}
