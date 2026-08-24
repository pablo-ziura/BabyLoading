import Foundation

struct BellyTrackingManifest: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1
    static let empty = BellyTrackingManifest(
        schemaVersion: currentSchemaVersion,
        settings: .default,
        entries: []
    )

    let schemaVersion: Int
    var settings: BellyTrackingSettings
    var entries: [BellyTrackingEntry]
}
