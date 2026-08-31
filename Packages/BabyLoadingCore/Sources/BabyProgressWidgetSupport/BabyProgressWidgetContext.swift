import AppLocalization
import Foundation
import PregnancyContent

public struct BabyProgressWidgetContext: Equatable, Sendable {
    public let lastPeriodDate: Date?
    public let weeklyContent: [WeekContent]
    public let language: AppLanguage

    public init(
        lastPeriodDate: Date?,
        weeklyContent: [WeekContent],
        language: AppLanguage
    ) {
        self.lastPeriodDate = lastPeriodDate
        self.weeklyContent = weeklyContent
        self.language = language
    }
}
