import Foundation

struct BackupProfile: Codable {
    var records: [String: BackupRecord] = [:]
    var mutations: [BackupMutation] = []
    var lastPeriodDay: String?
    var cadenceDays: Int?
    var importedGuestIDs: Set<String> = []
}

struct BackupDatabase: Codable {
    var schemaVersion = 1
    var activeProfileID = "guest"
    var guestID = UUID().uuidString
    var legacyMigrationComplete = false
    var profiles: [String: BackupProfile] = ["guest": BackupProfile()]
    var pendingAccountDeletion: String?
    var filesToRemove: [String] = []
    var legacyFilesToRemove: [String] = []
}
