import Foundation

public struct BellyTrackingEntry: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let imageFileName: String
    public let capturedAt: Date
    public let pregnancyWeekAtCapture: Int?

    public init(
        id: UUID = UUID(),
        imageFileName: String,
        capturedAt: Date = .now,
        pregnancyWeekAtCapture: Int?
    ) {
        self.id = id
        self.imageFileName = imageFileName
        self.capturedAt = capturedAt
        self.pregnancyWeekAtCapture = pregnancyWeekAtCapture
    }
}
