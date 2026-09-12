import Foundation

public actor ImageUploadService {
    private let localStore: BackupLocalStore
    private let storage: any BackupImageStorageProtocol
    private let preparer: any BackupImagePreparingProtocol
    private let synchronize: SynchronizeBackupUseCase
    private let temporaryDirectory: URL
    private var generation = UUID()
    private var runningSession: UUID?

    public init(
        localStore: BackupLocalStore,
        storage: any BackupImageStorageProtocol,
        preparer: any BackupImagePreparingProtocol,
        synchronize: SynchronizeBackupUseCase,
        temporaryDirectory: URL
    ) {
        self.localStore = localStore
        self.storage = storage
        self.preparer = preparer
        self.synchronize = synchronize
        self.temporaryDirectory = temporaryDirectory
    }

    public func execute(account: BackupAccount) async throws {
        guard !account.isAnonymous, runningSession != generation else { return }
        let session = generation
        runningSession = session
        defer { if runningSession == session { runningSession = nil } }
        try await synchronize.execute(account: account)
        try validate(session)
        let snapshot = try await localStore.snapshot()
        guard snapshot.profileID == account.id else { throw BackupFailure.sessionChanged }
        for logID in snapshot.pendingImageDeletions {
            try validate(session)
            try await storage.delete(userID: account.id, logID: logID)
            try validate(session)
            try await localStore.acknowledgeImageDeletion(logID: logID, userID: account.id)
        }
        for record in snapshot.records where !record.remote.isDeleted && record.failure == nil {
            try validate(session)
            let current = try await localStore.snapshot()
            guard current.profileID == account.id else { throw BackupFailure.sessionChanged }
            guard let latest = current.records.first(where: { $0.remote.id == record.remote.id }),
                  !latest.remote.isDeleted, latest.failure == nil else { continue }
            do {
                if latest.remote.remoteImageUrl == nil {
                    try await upload(latest, account: account, session: session)
                } else if latest.localImagePath == nil {
                    try await download(latest, account: account, session: session)
                }
            } catch {
                try validate(session)
                let failure = (error as? BackupFailure) ?? .storage
                if failure == .cancelled { continue }
                if !failure.isTransient {
                    try await localStore.recordFailure(logID: record.remote.id, failure: failure, userID: account.id)
                }
                if failure.isTransient {
                    try await localStore.markPending(logID: record.remote.id, userID: account.id)
                    throw failure
                }
            }
        }
    }

    public func cancel() async {
        generation = UUID()
        await storage.cancelAll()
    }

    private func upload(_ record: BackupRecord, account: BackupAccount, session: UUID) async throws {
        guard let path = record.localImagePath else { throw BackupFailure.missingImage }
        let source = try await localStore.imageURL(path: path)
        let temporary = try makeTemporaryURL()
        defer { removeTemporaryFile(temporary) }
        try await localStore.markUploading(logID: record.remote.id, userID: account.id)
        try await preparer.prepareJPEG(from: source, to: temporary)
        try validate(session)
        let url = try await storage.upload(fileURL: temporary, userID: account.id, logID: record.remote.id)
        try validate(session)
        try await localStore.recordUploadedImage(logID: record.remote.id, url: url, userID: account.id)
        try await synchronize.execute(account: account)
    }

    private func download(_ record: BackupRecord, account: BackupAccount, session: UUID) async throws {
        let temporary = try makeTemporaryURL()
        defer { removeTemporaryFile(temporary) }
        try await storage.download(to: temporary, userID: account.id, logID: record.remote.id)
        try validate(session)
        try await preparer.validateDownloadedJPEG(at: temporary)
        try validate(session)
        try await localStore.installDownloadedImage(fileURL: temporary, logID: record.remote.id, userID: account.id)
    }

    private func validate(_ session: UUID) throws {
        try Task.checkCancellation()
        guard session == generation else { throw BackupFailure.sessionChanged }
    }

    private func makeTemporaryURL() throws -> URL {
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        return temporaryDirectory.appendingPathComponent("\(UUID().uuidString).jpg")
    }

    private func removeTemporaryFile(_ url: URL) {
        // Temporary exports are disposable; a failed removal does not invalidate a committed backup.
        try? FileManager.default.removeItem(at: url)
    }
}
