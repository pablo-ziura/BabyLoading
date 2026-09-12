public enum SyncStatus: String, Codable, Equatable, Sendable {
    case pending
    case uploading
    case synced
}
