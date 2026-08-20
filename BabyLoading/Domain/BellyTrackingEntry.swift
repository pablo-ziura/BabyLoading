import Foundation

struct BellyTrackingEntry: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let imageFileName: String
    let capturedAt: Date
    let pregnancyWeekAtCapture: Int?

    init(
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

struct UltrasoundPhoto: Identifiable, Equatable, Sendable {
    let id: String
    let data: Data
}
