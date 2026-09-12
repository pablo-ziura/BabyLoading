import Foundation

public enum BackupFailure: String, Error, Codable, Sendable {
    case network
    case credentials
    case emailAlreadyInUse
    case weakPassword
    case recentLoginRequired
    case permissionDenied
    case quotaExceeded
    case invalidData
    case missingImage
    case storage
    case cancelled
    case sessionChanged
    case unavailable
}

public struct BackupAccount: Equatable, Sendable {
    public let id: String
    public let email: String?
    public let isAnonymous: Bool
    public let providers: [String]
    public let isEmailVerified: Bool

    public init(id: String, email: String?, isAnonymous: Bool, providers: [String], isEmailVerified: Bool) {
        self.id = id
        self.email = email
        self.isAnonymous = isAnonymous
        self.providers = providers
        self.isEmailVerified = isEmailVerified
    }
}

public enum BackupPhotoOrigin: String, Codable, Sendable {
    case ultrasound
    case bellyTracking
}

public struct RemotePregnancyLog: Codable, Equatable, Identifiable, Sendable {
    public var schemaVersion = 1
    public let id: String
    public let origin: BackupPhotoOrigin
    public let sourceID: String
    public let capturedAt: Date?
    public var weekNumber: Int?
    public var notes: String?
    public var remoteImageUrl: String?
    public var isDeleted: Bool

    public init(
        id: String,
        origin: BackupPhotoOrigin,
        sourceID: String,
        capturedAt: Date?,
        weekNumber: Int?,
        notes: String?,
        remoteImageUrl: String?,
        isDeleted: Bool
    ) {
        self.id = id
        self.origin = origin
        self.sourceID = sourceID
        self.capturedAt = capturedAt
        self.weekNumber = weekNumber
        self.notes = notes
        self.remoteImageUrl = remoteImageUrl
        self.isDeleted = isDeleted
    }
}

public struct BackupRecord: Codable, Equatable, Sendable {
    public var remote: RemotePregnancyLog
    public var localImagePath: String?
    public var syncStatus: SyncStatus
    public var failure: BackupFailure?

    public var log: PregnancyLog {
        PregnancyLog(
            id: remote.id, weekNumber: remote.weekNumber, notes: remote.notes,
            localImagePath: localImagePath, remoteImageUrl: remote.remoteImageUrl,
            syncStatus: syncStatus
        )
    }
}

public struct RemotePregnancySettings: Equatable, Sendable {
    public let lastPeriodDay: String?
    public let cadenceDays: Int?

    public init(lastPeriodDay: String?, cadenceDays: Int?) {
        self.lastPeriodDay = lastPeriodDay
        self.cadenceDays = cadenceDays
    }
}

public enum BackupMutationPayload: Codable, Equatable, Sendable {
    case create(RemotePregnancyLog)
    case edit(logID: String, weekNumber: Int?, notes: String?)
    case delete(logID: String)
    case image(logID: String, url: String)
    case lastPeriodDay(String?)
    case cadence(Int)

    public var logID: String? {
        switch self {
        case let .create(log): log.id
        case let .edit(id, _, _), let .delete(id), let .image(id, _): id
        case .lastPeriodDay, .cadence: nil
        }
    }
}

public struct BackupMutation: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let payload: BackupMutationPayload

    public init(payload: BackupMutationPayload) {
        id = UUID().uuidString.lowercased()
        self.payload = payload
    }
}

public struct BackupLocalSnapshot: Sendable {
    public let profileID: String
    public let records: [BackupRecord]
    public let mutations: [BackupMutation]
    public let settings: RemotePregnancySettings
    public let hasGuestData: Bool
    public let confirmedAccountDeletion: String?
    public let pendingAccountDeletion: String?
}

public enum BackupRemoteEvent: Sendable {
    case logs([RemotePregnancyLog])
    case settings(RemotePregnancySettings)
}

public protocol BackupRemoteStoreProtocol: Sendable {
    func apply(_ mutation: BackupMutation, userID: String) async throws
    func fetch(userID: String) async throws -> [BackupRemoteEvent]
    func observe(userID: String) async throws -> AsyncThrowingStream<BackupRemoteEvent, Error>
    func reset() async throws
}

public protocol BackupImageStorageProtocol: Sendable {
    func upload(fileURL: URL, userID: String, logID: String) async throws -> String
    func download(to fileURL: URL, userID: String, logID: String) async throws
    func delete(userID: String, logID: String) async throws
    func cancelAll() async
}

public protocol BackupImagePreparingProtocol: Sendable {
    func prepareJPEG(from source: URL, to destination: URL) async throws
    func validateDownloadedJPEG(at url: URL) async throws
}

@MainActor
public protocol BackupAuthenticationProtocol: AnyObject, Sendable {
    var currentAccount: BackupAccount? { get }
    func observeAccounts() -> AsyncStream<BackupAccount?>
    func signInAnonymously() async throws
    func linkEmail(email: String, password: String) async throws
    func signInEmail(email: String, password: String) async throws
    func signInGoogle(linkAnonymous: Bool) async throws
    func resetPassword(email: String) async throws
    func sendVerification() async throws
    func reauthenticate(password: String) async throws
    func signOut() throws
    func deleteAccount() async throws
}
