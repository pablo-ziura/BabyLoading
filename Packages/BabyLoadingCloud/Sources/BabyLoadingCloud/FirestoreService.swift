import CloudBackup
import FirebaseFirestore
import Foundation

public actor FirestoreService: BackupRemoteStoreProtocol {
    private let makeClient: @Sendable () throws -> Firestore
    private var client: Firestore
    private enum ResetPhase { case ready, disabling, terminating, clearing, recreating }
    private var resetPhase = ResetPhase.ready
    private var isResetting = false
    private var generation = UUID()
    private var cancellations: [UUID: @Sendable () -> Void] = [:]
    private var listeners: [UUID: [ListenerRegistration]] = [:]
    private var streams: [UUID: AsyncThrowingStream<BackupRemoteEvent, Error>.Continuation] = [:]

    public init(makeClient: @escaping @Sendable () throws -> Firestore) throws {
        self.makeClient = makeClient
        client = try makeClient()
        Self.configure(client)
    }

    private static func configure(_ client: Firestore) {
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: 100 * 1024 * 1024))
        client.settings = settings
    }

    public func apply(_ mutation: BackupMutation, userID: String) async throws {
        guard resetPhase == .ready else { throw BackupFailure.unavailable }
        try Self.validateIdentifier(userID)
        try Self.validateIdentifier(mutation.id)
        if let logID = mutation.payload.logID { try Self.validateIdentifier(logID) }
        try Task.checkCancellation()
        let session = generation
        let receipt = client.document("users/\(userID)/mutations/\(mutation.id)")
        let path = mutation.payload.logID.map { "pregnancyLogs/\($0)" } ?? "settings/pregnancy"
        let document = client.document("users/\(userID)/\(path)")
        let _: Void = try await request { complete in
            client.runTransaction({ transaction, errorPointer in
                do {
                    if try transaction.getDocument(receipt).exists { return nil }
                    let previous = try transaction.getDocument(document)
                    if let fields = try FirestoreMutationEncoder.fields(for: mutation.payload, previous: previous) {
                        transaction.setData(fields, forDocument: document, merge: true)
                    }
                    transaction.setData([
                        "schemaVersion": 1, "documentPath": path, "appliedAt": FieldValue.serverTimestamp()
                    ], forDocument: receipt)
                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }, completion: { _, error in
                if let error { complete(.failure(FirebaseFailureMapper.map(error))) } else { complete(.success(())) }
            })
        }
        guard session == generation else { throw BackupFailure.sessionChanged }
        try Task.checkCancellation()
    }

    public func fetch(userID: String) async throws -> [BackupRemoteEvent] {
        guard resetPhase == .ready else { throw BackupFailure.unavailable }
        try Self.validateIdentifier(userID)
        let session = generation
        let logs: [RemotePregnancyLog] = try await request { complete in
            client.collection("users/\(userID)/pregnancyLogs").getDocuments(source: .server) { snapshot, error in
                complete(Result {
                    if let error { throw FirebaseFailureMapper.map(error) }
                    guard let snapshot else { throw BackupFailure.unavailable }
                    return try snapshot.documents.map(Self.decodeLog)
                })
            }
        }
        guard session == generation else { throw BackupFailure.sessionChanged }
        let settings: RemotePregnancySettings = try await request { complete in
            client.document("users/\(userID)/settings/pregnancy").getDocument(source: .server) { snapshot, error in
                complete(Result {
                    if let error { throw FirebaseFailureMapper.map(error) }
                    guard let snapshot else { throw BackupFailure.unavailable }
                    return try Self.decodeSettings(snapshot)
                })
            }
        }
        guard session == generation else { throw BackupFailure.sessionChanged }
        return [.logs(logs), .settings(settings)]
    }

    public func observe(userID: String) throws -> AsyncThrowingStream<BackupRemoteEvent, Error> {
        guard resetPhase == .ready else { throw BackupFailure.unavailable }
        try Self.validateIdentifier(userID)
        let identifier = UUID()
        let pair = AsyncThrowingStream<BackupRemoteEvent, Error>.makeStream(bufferingPolicy: .unbounded)
        streams[identifier] = pair.continuation
        let logs = client.collection("users/\(userID)/pregnancyLogs").addSnapshotListener { snapshot, error in
            do {
                if let error { throw FirebaseFailureMapper.map(error) }
                guard let snapshot, !snapshot.metadata.hasPendingWrites else { return }
                pair.continuation.yield(.logs(try snapshot.documents.map(Self.decodeLog)))
            } catch { pair.continuation.finish(throwing: error) }
        }
        let settings = client.document("users/\(userID)/settings/pregnancy").addSnapshotListener { snapshot, error in
            do {
                if let error { throw FirebaseFailureMapper.map(error) }
                guard let snapshot, !snapshot.metadata.hasPendingWrites else { return }
                pair.continuation.yield(.settings(try Self.decodeSettings(snapshot)))
            } catch { pair.continuation.finish(throwing: error) }
        }
        listeners[identifier] = [logs, settings]
        pair.continuation.onTermination = { [weak self] _ in
            Task { await self?.removeListeners(identifier) }
        }
        return pair.stream
    }

    public func reset() async throws {
        guard !isResetting else { throw BackupFailure.sessionChanged }
        isResetting = true
        defer { isResetting = false }
        generation = UUID()
        for identifier in Array(cancellations.keys) { cancelRequest(identifier) }
        for identifier in Array(listeners.keys) { removeListeners(identifier) }
        if resetPhase == .ready || resetPhase == .disabling {
            resetPhase = .disabling
            try await client.disableNetwork()
            resetPhase = .terminating
        }
        if resetPhase == .terminating {
            try await client.terminate()
            resetPhase = .clearing
        }
        if resetPhase == .clearing {
            try await client.clearPersistence()
            resetPhase = .recreating
        }
        client = try makeClient()
        Self.configure(client)
        resetPhase = .ready
    }

    private func request<Value: Sendable>(
        _ start: (@escaping @Sendable (Result<Value, Error>) -> Void) -> Void
    ) async throws -> Value {
        let identifier = UUID()
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                cancellations[identifier] = { continuation.resume(throwing: BackupFailure.cancelled) }
                start { [weak self] result in
                    Task { await self?.finishRequest(identifier, continuation: continuation, result: result) }
                }
            }
        } onCancel: {
            Task { await self.cancelRequest(identifier) }
        }
    }

    private func finishRequest<Value: Sendable>(
        _ identifier: UUID, continuation: CheckedContinuation<Value, Error>, result: Result<Value, Error>
    ) {
        guard cancellations.removeValue(forKey: identifier) != nil else { return }
        continuation.resume(with: result)
    }

    private func cancelRequest(_ identifier: UUID) { cancellations.removeValue(forKey: identifier)?() }

    private func removeListeners(_ identifier: UUID) {
        listeners.removeValue(forKey: identifier)?.forEach { $0.remove() }
        streams.removeValue(forKey: identifier)?.finish()
    }

    private static func decodeLog(_ document: DocumentSnapshot) throws -> RemotePregnancyLog {
        let log = try document.data(as: RemotePregnancyLog.self)
        guard log.schemaVersion == 1, log.id == document.documentID,
              !log.sourceID.isEmpty, log.sourceID.count <= 1024,
              log.id == BackupLocalStore.photoID(origin: log.origin, sourceID: log.sourceID) else {
            throw BackupFailure.invalidData
        }
        return log
    }

    private static func decodeSettings(_ document: DocumentSnapshot) throws -> RemotePregnancySettings {
        guard let fields = document.data() else { return RemotePregnancySettings(lastPeriodDay: nil, cadenceDays: nil) }
        guard fields["schemaVersion"] as? Int == 1 else { throw BackupFailure.invalidData }
        let day = fields["lastPeriodDay"] as? String
        let cadence = fields["cadenceDays"] as? Int
        if let day { _ = try PregnancyCalendarDay.decode(day, calendar: Calendar(identifier: .gregorian)) }
        if let cadence, ![7, 14, 28].contains(cadence) { throw BackupFailure.invalidData }
        return RemotePregnancySettings(lastPeriodDay: day, cadenceDays: cadence)
    }

    private static func validateIdentifier(_ value: String) throws {
        guard !value.isEmpty, value.count <= 128,
              value.unicodeScalars.allSatisfy({
                  CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_.")).contains($0)
              }), value != ".", value != ".." else { throw BackupFailure.invalidData }
    }
}
