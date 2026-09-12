import Foundation

extension BackupLocalStore {
    public func acknowledge(_ mutation: BackupMutation, userID: String) throws {
        var database = try loadForUser(userID)
        database.profiles[userID]?.mutations.removeAll { $0.id == mutation.id }
        if let id = mutation.payload.logID,
           let profile = database.profiles[userID],
           !profile.mutations.contains(where: { $0.payload.logID == id }),
           profile.records[id]?.remote.remoteImageUrl != nil || profile.records[id]?.remote.isDeleted == true {
            database.profiles[userID]?.records[id]?.syncStatus = .synced
            database.profiles[userID]?.records[id]?.failure = nil
        }
        try save(database)
    }

    public func markUploading(logID: String, userID: String) throws {
        var database = try loadForUser(userID)
        guard database.profiles[userID]?.records[logID]?.remote.isDeleted == false else {
            throw BackupFailure.cancelled
        }
        database.profiles[userID]?.records[logID]?.syncStatus = .uploading
        database.profiles[userID]?.records[logID]?.failure = nil
        try save(database)
    }

    public func recordUploadedImage(logID: String, url: String, userID: String) throws {
        var database = try loadForUser(userID)
        guard database.profiles[userID]?.records[logID]?.remote.isDeleted == false else {
            throw BackupFailure.cancelled
        }
        database.profiles[userID]?.records[logID]?.remote.remoteImageUrl = url
        database.profiles[userID]?.records[logID]?.syncStatus = .pending
        database.profiles[userID]?.mutations.append(BackupMutation(payload: .image(logID: logID, url: url)))
        try save(database)
    }

    public func recordFailure(logID: String, failure: BackupFailure, userID: String) throws {
        var database = try loadForUser(userID)
        database.profiles[userID]?.records[logID]?.failure = failure
        database.profiles[userID]?.records[logID]?.syncStatus = .pending
        try save(database)
    }

    public func acknowledgeImageDeletion(logID: String, userID: String) throws {
        var database = try loadForUser(userID)
        database.profiles[userID]?.pendingImageDeletions?.remove(logID)
        try save(database)
    }

    public func markPending(logID: String, userID: String) throws {
        var database = try loadForUser(userID)
        database.profiles[userID]?.records[logID]?.syncStatus = .pending
        try save(database)
    }

    public func retryFailures() throws {
        var database = try load()
        for id in database.profiles[database.activeProfileID]?.records.keys.map({ $0 }) ?? [] {
            database.profiles[database.activeProfileID]?.records[id]?.failure = nil
            if database.profiles[database.activeProfileID]?.records[id]?.syncStatus == .uploading {
                database.profiles[database.activeProfileID]?.records[id]?.syncStatus = .pending
            }
        }
        try save(database)
    }

    public func merge(logs: [RemotePregnancyLog], userID: String) throws {
        var database = try loadForUser(userID)
        guard var profile = database.profiles[userID] else { throw BackupFailure.sessionChanged }
        for remote in logs {
            guard remote.schemaVersion == 1, !remote.sourceID.isEmpty, remote.sourceID.count <= 1024,
                  remote.id == Self.photoID(origin: remote.origin, sourceID: remote.sourceID) else {
                throw BackupFailure.invalidData
            }
            if remote.origin == .bellyTracking, UUID(uuidString: remote.sourceID) == nil {
                throw BackupFailure.invalidData
            }
            let local = profile.records[remote.id]
            if remote.isDeleted {
                if local?.remote.isDeleted != true {
                    profile.pendingImageDeletions = (profile.pendingImageDeletions ?? []).union([remote.id])
                }
                if let path = local?.localImagePath { database.filesToRemove.append(path) }
                profile.records[remote.id] = BackupRecord(
                    remote: remote, localImagePath: nil, syncStatus: .synced, failure: nil
                )
                profile.mutations.removeAll { $0.payload.logID == remote.id }
            } else if local?.remote.isDeleted != true {
                let pending = profile.mutations.contains { $0.payload.logID == remote.id }
                if !pending {
                    profile.records[remote.id] = BackupRecord(
                        remote: remote, localImagePath: local?.localImagePath,
                        syncStatus: remote.remoteImageUrl == nil ? .pending : .synced, failure: local?.failure
                    )
                }
            }
        }
        database.profiles[userID] = profile
        try save(database)
        try removeObsoleteFiles()
    }

    public func merge(settings: RemotePregnancySettings, userID: String) throws {
        if let day = settings.lastPeriodDay {
            _ = try PregnancyCalendarDay.decode(day, calendar: Calendar(identifier: .gregorian))
        }
        if let cadence = settings.cadenceDays, ![7, 14, 28].contains(cadence) { throw BackupFailure.invalidData }
        var database = try loadForUser(userID)
        guard var profile = database.profiles[userID] else { throw BackupFailure.sessionChanged }
        if !profile.mutations.contains(where: { if case .lastPeriodDay = $0.payload { return true }; return false }) {
            profile.lastPeriodDay = settings.lastPeriodDay
        }
        if !profile.mutations.contains(where: { if case .cadence = $0.payload { return true }; return false }) {
            profile.cadenceDays = settings.cadenceDays
        }
        database.profiles[userID] = profile
        try save(database)
    }

    public func installDownloadedImage(fileURL: URL, logID: String, userID: String) throws {
        var database = try loadForUser(userID)
        guard database.profiles[userID]?.records[logID]?.remote.isDeleted == false else {
            throw BackupFailure.cancelled
        }
        let path = "\(UUID().uuidString).jpg"
        let destination = try assetURL(path)
        try fileManager.copyItem(at: fileURL, to: destination)
        database.profiles[userID]?.records[logID]?.localImagePath = path
        database.profiles[userID]?.records[logID]?.failure = nil
        do { try save(database) } catch {
            try fileManager.removeItem(at: destination)
            throw error
        }
    }

    public func containsRecord(origin: BackupPhotoOrigin, sourceID: String) throws -> Bool {
        let id = Self.photoID(origin: origin, sourceID: sourceID)
        return try load().profiles.values.contains { $0.records[id] != nil }
    }

    public func needsLegacyMigration() throws -> Bool { try !load().legacyMigrationComplete }

    public func finishLegacyMigration() throws {
        var database = try load()
        database.legacyMigrationComplete = true
        try save(database)
    }
}
