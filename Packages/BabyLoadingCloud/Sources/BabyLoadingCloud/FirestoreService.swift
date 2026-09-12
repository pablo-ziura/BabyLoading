import CloudBackup
import FirebaseFirestore
import Foundation

public actor FirestoreService: BackupRemoteStoreProtocol {
    private let makeClient: @Sendable () throws -> Firestore
    private var client: Firestore
    private var generation = UUID()
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
        try Self.validateIdentifier(userID)
        try Self.validateIdentifier(mutation.id)
        if let logID = mutation.payload.logID { try Self.validateIdentifier(logID) }
        try Task.checkCancellation()
        let session = generation
        let receipt = client.document("users/\(userID)/mutations/\(mutation.id)")
        let path = mutation.payload.logID.map { "pregnancyLogs/\($0)" } ?? "settings/pregnancy"
        let document = client.document("users/\(userID)/\(path)")
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
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
                if let error {
                    continuation.resume(throwing: FirebaseFailureMapper.map(error))
                } else {
                    continuation.resume()
                }
            })
        }
        guard session == generation else { throw BackupFailure.sessionChanged }
        try Task.checkCancellation()
    }

    public func fetch(userID: String) async throws -> [BackupRemoteEvent] {
        try Self.validateIdentifier(userID)
        let session = generation
        let logs: [RemotePregnancyLog] = try await withCheckedThrowingContinuation { continuation in
            client.collection("users/\(userID)/pregnancyLogs").getDocuments(source: .server) { snapshot, error in
                do {
                    if let error { throw FirebaseFailureMapper.map(error) }
                    guard let snapshot else { throw BackupFailure.unavailable }
                    continuation.resume(returning: try snapshot.documents.map(Self.decodeLog))
                } catch { continuation.resume(throwing: error) }
            }
        }
        let settings: RemotePregnancySettings = try await withCheckedThrowingContinuation { continuation in
            client.document("users/\(userID)/settings/pregnancy").getDocument(source: .server) { snapshot, error in
                do {
                    if let error { throw FirebaseFailureMapper.map(error) }
                    guard let snapshot else { throw BackupFailure.unavailable }
                    continuation.resume(returning: try Self.decodeSettings(snapshot))
                } catch { continuation.resume(throwing: error) }
            }
        }
        guard session == generation else { throw BackupFailure.sessionChanged }
        return [.logs(logs), .settings(settings)]
    }

    public func observe(userID: String) throws -> AsyncThrowingStream<BackupRemoteEvent, Error> {
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
        generation = UUID()
        for identifier in Array(listeners.keys) { removeListeners(identifier) }
        try await client.disableNetwork()
        try await client.terminate()
        try await client.clearPersistence()
        client = try makeClient()
        Self.configure(client)
    }

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
