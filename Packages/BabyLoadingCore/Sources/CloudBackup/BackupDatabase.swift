import Foundation

struct BackupProfile: Codable {
    var pendingImageDeletions: Set<String>?
    var records: [String: BackupRecord] = [:]
    var mutations: [BackupMutation] = []
    var lastPeriodDay: String?
    var cadenceDays: Int?
    var importedGuestIDs: Set<String> = []
}

struct BackupPendingFile: Codable {
    let profileID: String
    let record: BackupRecord
    let mutation: BackupMutation?
}

struct BackupDatabase: Codable {
    var pendingFiles: [BackupPendingFile]?
    var schemaVersion = 1
    var activeProfileID = "guest"
    var guestID = UUID().uuidString
    var legacyMigrationComplete = false
    var profiles: [String: BackupProfile] = ["guest": BackupProfile()]
    var confirmedAccountDeletion: String?
    var pendingGuestLinkID: String?
    var pendingAccountDeletion: String?
    var filesToRemove: [String] = []
}
