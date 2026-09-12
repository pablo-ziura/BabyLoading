import CryptoKit
import Foundation

public actor BackupLocalStore {
    let root: URL
    let fileManager = FileManager()
    var observers: [UUID: AsyncStream<Void>.Continuation] = [:]

    public init(containerURL: URL) {
        root = containerURL.appendingPathComponent("cloud-backup", isDirectory: true)
    }

    public func isInitialized() -> Bool {
        fileManager.fileExists(atPath: root.appendingPathComponent("manifest.json").path)
    }

    public func initializeEmpty(lastPeriodDay: String?, cadenceDays: Int) throws {
        guard !isInitialized() else { return }
        var database = BackupDatabase()
        var profile = BackupProfile()
        profile.lastPeriodDay = lastPeriodDay
        profile.cadenceDays = cadenceDays
        profile.mutations.append(BackupMutation(payload: .lastPeriodDay(lastPeriodDay)))
        profile.mutations.append(BackupMutation(payload: .cadence(cadenceDays)))
        database.profiles["guest"] = profile
        try save(database)
    }

    public func snapshot() throws -> BackupLocalSnapshot {
        let database = try load()
        let profile = database.profiles[database.activeProfileID] ?? BackupProfile()
        let guest = database.profiles["guest"] ?? BackupProfile()
        return BackupLocalSnapshot(
            profileID: database.activeProfileID,
            records: Array(profile.records.values), mutations: profile.mutations,
            settings: RemotePregnancySettings(lastPeriodDay: profile.lastPeriodDay, cadenceDays: profile.cadenceDays),
            hasGuestData: guest.records.values.contains { !$0.remote.isDeleted } || guest.lastPeriodDay != nil,
            pendingAccountDeletion: database.pendingAccountDeletion
        )
    }

    public func changes() -> AsyncStream<Void> {
        let identifier = UUID()
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            observers[identifier] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeObserver(identifier) }
            }
        }
    }

    private func removeObserver(_ id: UUID) { observers[id] = nil }

    public func activate(userID: String?, adoptGuest: Bool) throws {
        var database = try load()
        let destination = userID ?? "guest"
        guard destination == "guest" || Self.isSafeIdentifier(destination) else { throw BackupFailure.invalidData }
        if database.profiles[destination] == nil { database.profiles[destination] = BackupProfile() }
        if adoptGuest, destination != "guest" {
            try importGuest(into: destination, database: &database)
        }
        database.activeProfileID = destination
        for id in database.profiles[destination]?.records.keys.map({ $0 }) ?? []
            where database.profiles[destination]?.records[id]?.syncStatus == .uploading {
            database.profiles[destination]?.records[id]?.syncStatus = .pending
        }
        try save(database)
    }

    public func importGuest(userID: String) throws {
        var database = try loadForUser(userID)
        try importGuest(into: userID, database: &database)
        try save(database)
    }

    private func importGuest(into destination: String, database: inout BackupDatabase) throws {
        var target = database.profiles[destination] ?? BackupProfile()
        guard !target.importedGuestIDs.contains(database.guestID) else { return }
        let guest = database.profiles["guest"] ?? BackupProfile()
        for (id, record) in guest.records where !record.remote.isDeleted && target.records[id] == nil {
            var imported = record
            imported.remote.remoteImageUrl = nil
            imported.syncStatus = .pending
            imported.failure = nil
            target.records[id] = imported
            target.mutations.append(BackupMutation(payload: .create(imported.remote)))
        }
        if target.lastPeriodDay == nil, let day = guest.lastPeriodDay {
            target.lastPeriodDay = day
            target.mutations.append(BackupMutation(payload: .lastPeriodDay(day)))
        }
        if target.cadenceDays == nil, let cadence = guest.cadenceDays {
            target.cadenceDays = cadence
            target.mutations.append(BackupMutation(payload: .cadence(cadence)))
        }
        target.importedGuestIDs.insert(database.guestID)
        database.profiles[destination] = target
        database.profiles["guest"] = BackupProfile()
        database.guestID = UUID().uuidString
    }

    public func beginAccountDeletion(userID: String) throws {
        var database = try loadForUser(userID)
        database.pendingAccountDeletion = userID
        try save(database)
    }

    public func cancelAccountDeletion() throws {
        var database = try load()
        database.pendingAccountDeletion = nil
        try save(database)
    }

    public func finishAccountDeletion(userID: String) throws {
        var database = try load()
        guard database.pendingAccountDeletion == userID else { throw BackupFailure.sessionChanged }
        let paths = database.profiles[userID]?.records.values.compactMap(\.localImagePath) ?? []
        database.profiles[userID] = nil
        database.filesToRemove.append(contentsOf: paths)
        database.activeProfileID = "guest"
        database.pendingAccountDeletion = nil
        try save(database)
        try removeObsoleteFiles()
    }

    public func removeObsoleteFiles() throws {
        var database = try load()
        let retained = Set(database.profiles.values.flatMap { $0.records.values.compactMap(\.localImagePath) })
        for path in database.filesToRemove where !retained.contains(path) {
            let url = try assetURL(path)
            if fileManager.fileExists(atPath: url.path) { try fileManager.removeItem(at: url) }
        }
        database.filesToRemove = []
        try save(database, notify: false)
    }

    public func addImage(
        data: Data, fileExtension: String, origin: BackupPhotoOrigin,
        sourceID: String, capturedAt: Date?, weekNumber: Int?
    ) throws -> BackupRecord {
        var database = try load()
        let identifier = Self.photoID(origin: origin, sourceID: sourceID)
        var profile = database.profiles[database.activeProfileID] ?? BackupProfile()
        if let existing = profile.records[identifier] { return existing }
        guard ["jpg", "jpeg", "heic", "png"].contains(fileExtension) else { throw BackupFailure.invalidData }
        let path = "\(UUID().uuidString).\(fileExtension)"
        let destination = try assetURL(path)
        try data.write(to: destination, options: .atomic)
        let record = BackupRecord(
            remote: RemotePregnancyLog(
                id: identifier, origin: origin, sourceID: sourceID, capturedAt: capturedAt,
                weekNumber: weekNumber, notes: nil, remoteImageUrl: nil, isDeleted: false
            ),
            localImagePath: path, syncStatus: .pending, failure: nil
        )
        profile.records[identifier] = record
        profile.mutations.append(BackupMutation(payload: .create(record.remote)))
        database.profiles[database.activeProfileID] = profile
        do {
            try save(database)
        } catch {
            try fileManager.removeItem(at: destination)
            throw error
        }
        return record
    }

    public func deleteImage(origin: BackupPhotoOrigin, sourceID: String) throws {
        var database = try load()
        let id = Self.photoID(origin: origin, sourceID: sourceID)
        guard var profile = database.profiles[database.activeProfileID], var record = profile.records[id],
              !record.remote.isDeleted else { return }
        record.remote.isDeleted = true
        record.syncStatus = .pending
        if let path = record.localImagePath { database.filesToRemove.append(path) }
        record.localImagePath = nil
        profile.records[id] = record
        profile.mutations.removeAll { $0.payload.logID == id }
        profile.mutations.append(BackupMutation(payload: .delete(logID: id)))
        database.profiles[database.activeProfileID] = profile
        try save(database)
        try removeObsoleteFiles()
    }

    public func editLog(id: String, weekNumber: Int?, notes: String?) throws {
        var database = try load()
        guard var profile = database.profiles[database.activeProfileID], var record = profile.records[id],
              !record.remote.isDeleted else { throw BackupFailure.invalidData }
        record.remote.weekNumber = weekNumber
        record.remote.notes = notes
        record.syncStatus = .pending
        profile.records[id] = record
        profile.mutations.append(BackupMutation(payload: .edit(logID: id, weekNumber: weekNumber, notes: notes)))
        database.profiles[database.activeProfileID] = profile
        try save(database)
    }

    public func setLastPeriodDay(_ day: String?) throws {
        if let day { _ = try PregnancyCalendarDay.decode(day, calendar: Calendar(identifier: .gregorian)) }
        var database = try load()
        database.profiles[database.activeProfileID]?.lastPeriodDay = day
        database.profiles[database.activeProfileID]?.mutations.append(BackupMutation(payload: .lastPeriodDay(day)))
        try save(database)
    }

    public func setCadence(_ days: Int) throws {
        guard [7, 14, 28].contains(days) else { throw BackupFailure.invalidData }
        var database = try load()
        database.profiles[database.activeProfileID]?.cadenceDays = days
        database.profiles[database.activeProfileID]?.mutations.append(BackupMutation(payload: .cadence(days)))
        try save(database)
    }

    public func imageData(path: String) throws -> Data {
        let url = try assetURL(path)
        guard fileManager.fileExists(atPath: url.path) else { throw BackupFailure.missingImage }
        return try Data(contentsOf: url)
    }

    public func imageURL(path: String) throws -> URL { try assetURL(path) }

    public static func photoID(origin: BackupPhotoOrigin, sourceID: String) -> String {
        let hash = SHA256.hash(data: Data("\(origin.rawValue):\(sourceID)".utf8))
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    static func isSafeIdentifier(_ value: String) -> Bool {
        !value.isEmpty && value.count <= 128 && value != "." && value != ".."
            && value.unicodeScalars.allSatisfy {
                CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_.")).contains($0)
            }
    }

    func assetURL(_ path: String) throws -> URL {
        guard Self.isSafeIdentifier(path) else { throw BackupFailure.invalidData }
        let directory = root.appendingPathComponent("files", isDirectory: true)
        try ensureDirectory(root)
        try ensureDirectory(directory)
        let url = directory.appendingPathComponent(path)
        if fileManager.fileExists(atPath: url.path) {
            let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
            guard values.isRegularFile == true, values.isSymbolicLink != true else { throw BackupFailure.invalidData }
        }
        return url
    }

    func ensureDirectory(_ url: URL) throws {
        if fileManager.fileExists(atPath: url.path) {
            let values = try url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            guard values.isDirectory == true, values.isSymbolicLink != true else { throw BackupFailure.invalidData }
        } else {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    func loadForUser(_ userID: String) throws -> BackupDatabase {
        let database = try load()
        guard database.activeProfileID == userID, userID != "guest" else { throw BackupFailure.sessionChanged }
        return database
    }

    func load() throws -> BackupDatabase {
        try ensureDirectory(root)
        let url = root.appendingPathComponent("manifest.json")
        let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
        guard values.isRegularFile == true, values.isSymbolicLink != true else { throw BackupFailure.invalidData }
        let database = try JSONDecoder().decode(BackupDatabase.self, from: Data(contentsOf: url))
        guard database.schemaVersion == 1, database.profiles[database.activeProfileID] != nil else {
            throw BackupFailure.invalidData
        }
        return database
    }

    func save(_ database: BackupDatabase, notify: Bool = true) throws {
        try ensureDirectory(root)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        try encoder.encode(database).write(to: root.appendingPathComponent("manifest.json"), options: .atomic)
        if notify { for observer in observers.values { observer.yield(()) } }
    }
}
