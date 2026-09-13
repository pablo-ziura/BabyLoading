import CloudBackup
import FirebaseStorage
import Foundation

public actor FirebaseImageStorage: BackupImageStorageProtocol {
    private let storage: Storage
    private var generation = UUID()
    private var transfers: [UUID: StorageTransfer] = [:]
    private var completions: [UUID: CheckedContinuation<Void, Error>] = [:]

    public init(makeClient: @Sendable () throws -> Storage) throws {
        storage = try makeClient()
        storage.maxUploadRetryTime = 60
        storage.maxDownloadRetryTime = 60
        storage.maxOperationRetryTime = 30
    }

    public func upload(fileURL: URL, userID: String, logID: String) async throws -> String {
        let reference = try reference(userID: userID, logID: logID)
        let session = generation
        let identifier = UUID()
        try await withTaskCancellationHandler {
            try Task.checkCancellation()
            try await withCheckedThrowingContinuation { continuation in
                completions[identifier] = continuation
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"
                let task = reference.putFile(from: fileURL, metadata: metadata) { [weak self] _, error in
                    Task { await self?.finish(identifier, error: error) }
                }
                transfers[identifier] = .upload(task)
            }
        } onCancel: {
            Task { await self.cancel(identifier) }
        }
        guard session == generation else { throw BackupFailure.sessionChanged }
        try Task.checkCancellation()
        let url: String = try await withCheckedThrowingContinuation { continuation in
            reference.downloadURL { url, error in
                if let error {
                    continuation.resume(throwing: FirebaseFailureMapper.map(error))
                } else if let url {
                    continuation.resume(returning: url.absoluteString)
                } else {
                    continuation.resume(throwing: BackupFailure.storage)
                }
            }
        }
        guard session == generation else { throw BackupFailure.sessionChanged }
        return url
    }

    public func download(to fileURL: URL, userID: String, logID: String) async throws {
        let reference = try reference(userID: userID, logID: logID)
        let session = generation
        try await validateMetadata(reference)
        guard session == generation else { throw BackupFailure.sessionChanged }
        let identifier = UUID()
        try await withTaskCancellationHandler {
            try Task.checkCancellation()
            try await withCheckedThrowingContinuation { continuation in
                completions[identifier] = continuation
                transfers[identifier] = .download(reference.write(toFile: fileURL) { [weak self] _, error in
                    Task { await self?.finish(identifier, error: error) }
                })
            }
        } onCancel: {
            Task { await self.cancel(identifier) }
        }
        guard session == generation else { throw BackupFailure.sessionChanged }
        try Task.checkCancellation()
    }

    public func delete(userID: String, logID: String) async throws {
        let reference = try reference(userID: userID, logID: logID)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            reference.delete { error in
                if let error, FirebaseFailureMapper.map(error) != .missingImage {
                    continuation.resume(throwing: FirebaseFailureMapper.map(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    public func cancelAll() {
        generation = UUID()
        for identifier in Array(transfers.keys) { cancel(identifier) }
    }

    private func cancel(_ identifier: UUID) {
        transfers.removeValue(forKey: identifier)?.cancel()
        completions.removeValue(forKey: identifier)?.resume(throwing: BackupFailure.cancelled)
    }

    private func finish(_ identifier: UUID, error: Error?) {
        transfers[identifier] = nil
        guard let completion = completions.removeValue(forKey: identifier) else { return }
        if let error {
            completion.resume(throwing: FirebaseFailureMapper.map(error))
        } else {
            completion.resume()
        }
    }

    private func validateMetadata(_ reference: StorageReference) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            reference.getMetadata { metadata, error in
                if let error {
                    continuation.resume(throwing: FirebaseFailureMapper.map(error))
                } else if let metadata, metadata.contentType == "image/jpeg",
                          metadata.size > 0, metadata.size <= 25 * 1024 * 1024 {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: BackupFailure.invalidData)
                }
            }
        }
    }

    private func reference(userID: String, logID: String) throws -> StorageReference {
        guard !userID.isEmpty, userID.count <= 128, userID != ".", userID != "..",
              userID.unicodeScalars.allSatisfy({
                  CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_.")).contains($0)
              }), logID.count == 64, logID.allSatisfy({ $0.isHexDigit && !$0.isUppercase }) else {
            throw BackupFailure.invalidData
        }
        return storage.reference().child("users/\(userID)/photos/\(logID).jpg")
    }
}

private enum StorageTransfer {
    case upload(StorageUploadTask)
    case download(StorageDownloadTask)

    func cancel() {
        switch self {
        case let .upload(task): task.cancel()
        case let .download(task): task.cancel()
        }
    }
}
