import Foundation

public struct BabyProgressWidgetSnapshot: Equatable, Sendable {
    public let date: Date
    public let dueDate: Date?
    public let currentWeek: Int
    public let babySizeImageName: String
    public let babySizeLabel: String?
    public let localeIdentifier: String

    public init(
        date: Date,
        dueDate: Date?,
        currentWeek: Int,
        babySizeImageName: String,
        babySizeLabel: String?,
        localeIdentifier: String
    ) {
        self.date = date
        self.dueDate = dueDate
        self.currentWeek = currentWeek
        self.babySizeImageName = babySizeImageName
        self.babySizeLabel = babySizeLabel
        self.localeIdentifier = localeIdentifier
    }
}
