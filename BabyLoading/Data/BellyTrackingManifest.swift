import Foundation

struct BellyTrackingManifest: Codable, Equatable {
    static let currentSchemaVersion = 1
    static let empty = BellyTrackingManifest(
        schemaVersion: BellyTrackingManifest.currentSchemaVersion,
        settings: .default,
        entries: []
    )

    let schemaVersion: Int
    var settings: BellyTrackingSettings
    var entries: [BellyTrackingEntry]
}
