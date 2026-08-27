import Foundation
import PregnancyProgress

public struct BabyProgressWidgetSnapshot: Equatable, Sendable {
    public let date: Date
    public let state: BabyProgressWidgetState
    public let localeIdentifier: String

    public init(
        date: Date,
        state: BabyProgressWidgetState,
        localeIdentifier: String
    ) {
        self.date = date
        self.state = state
        self.localeIdentifier = localeIdentifier
    }

    public var requiresDailyTimelineRefresh: Bool {
        switch state {
        case .unconfigured, .invalidFutureLastPeriodDate:
            false
        case .ongoing, .lateTerm, .postTerm:
            true
        }
    }
}

public enum BabyProgressWidgetState: Equatable, Sendable {
    case unconfigured
    case invalidFutureLastPeriodDate
    case ongoing(
        progress: BabyProgressWidgetDetails,
        babySizeImageName: String,
        babySizeLabel: String?
    )
    case lateTerm(progress: BabyProgressWidgetDetails)
    case postTerm(progress: BabyProgressWidgetDetails)
}

public struct BabyProgressWidgetDetails: Equatable, Sendable {
    public let gestationalAge: GestationalAge
    public let dueDateRelation: DueDateRelation

    public init(
        gestationalAge: GestationalAge,
        dueDateRelation: DueDateRelation
    ) {
        self.gestationalAge = gestationalAge
        self.dueDateRelation = dueDateRelation
    }
}
