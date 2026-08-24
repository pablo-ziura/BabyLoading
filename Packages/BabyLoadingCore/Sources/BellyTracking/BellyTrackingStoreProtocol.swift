import Foundation

public protocol BellyTrackingStoreProtocol: Sendable {
    func loadTimeline() async throws -> [BellyTrackingEntry]
    func loadImageData(imageFileName: String) async throws -> Data?
    func capturePhoto(data: Data, capturedAt: Date, pregnancyWeekAtCapture: Int?) async throws -> BellyTrackingEntry
    func deleteEntry(id: UUID) async throws
    func loadSettings() async throws -> BellyTrackingSettings
    func updateSettings(_ settings: BellyTrackingSettings) async throws
}
