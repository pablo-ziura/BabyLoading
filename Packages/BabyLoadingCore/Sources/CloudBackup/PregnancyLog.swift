public struct PregnancyLog: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let weekNumber: Int?
    public let notes: String?
    public let localImagePath: String?
    public let remoteImageUrl: String?
    public let syncStatus: SyncStatus

    public init(
        id: String,
        weekNumber: Int?,
        notes: String?,
        localImagePath: String?,
        remoteImageUrl: String?,
        syncStatus: SyncStatus
    ) {
        self.id = id
        self.weekNumber = weekNumber
        self.notes = notes
        self.localImagePath = localImagePath
        self.remoteImageUrl = remoteImageUrl
        self.syncStatus = syncStatus
    }
}
