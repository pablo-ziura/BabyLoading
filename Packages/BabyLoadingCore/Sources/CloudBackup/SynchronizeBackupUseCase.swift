import Foundation

public struct SynchronizeBackupUseCase: Sendable {
    private let localStore: BackupLocalStore
    private let remoteStore: any BackupRemoteStoreProtocol

    public init(localStore: BackupLocalStore, remoteStore: any BackupRemoteStoreProtocol) {
        self.localStore = localStore
        self.remoteStore = remoteStore
    }

    public func execute(account: BackupAccount) async throws {
        guard !account.isAnonymous else { return }
        let snapshot = try await localStore.snapshot()
        guard snapshot.profileID == account.id else { throw BackupFailure.sessionChanged }
        var appliedMutation = false
        for mutation in snapshot.mutations {
            try Task.checkCancellation()
            let current = try await localStore.snapshot()
            guard current.profileID == account.id else { throw BackupFailure.sessionChanged }
            guard current.mutations.contains(where: { $0.id == mutation.id }) else { continue }
            if let logID = mutation.payload.logID,
               current.records.first(where: { $0.remote.id == logID })?.failure != nil { continue }
            do {
                try await remoteStore.apply(mutation, userID: account.id)
                try Task.checkCancellation()
                try await localStore.acknowledge(mutation, userID: account.id)
                appliedMutation = true
            } catch {
                if let failure = error as? BackupFailure, !failure.isTransient,
                   failure != .cancelled, failure != .sessionChanged, let logID = mutation.payload.logID {
                    try await localStore.recordFailure(logID: logID, failure: failure, userID: account.id)
                }
                throw error
            }
        }
        if appliedMutation { try await refresh(account: account) }
    }

    public func refresh(account: BackupAccount) async throws {
        guard !account.isAnonymous else { return }
        for event in try await remoteStore.fetch(userID: account.id) {
            try Task.checkCancellation()
            try await merge(event, userID: account.id)
        }
    }

    public func merge(_ event: BackupRemoteEvent, userID: String) async throws {
        switch event {
        case let .logs(logs): try await localStore.merge(logs: logs, userID: userID)
        case let .settings(settings): try await localStore.merge(settings: settings, userID: userID)
        }
    }
}

extension BackupFailure {
    public var isTransient: Bool { self == .network }
}
