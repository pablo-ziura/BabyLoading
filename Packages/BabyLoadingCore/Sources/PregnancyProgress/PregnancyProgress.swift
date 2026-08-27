import Foundation

public enum PregnancyProgress: Equatable, Sendable {
    case active(ActivePregnancyProgress)
    case invalidFutureLastPeriodDate(lastPeriodDate: Date)
}

public struct ActivePregnancyProgress: Equatable, Sendable {
    public let lastPeriodDate: Date
    public let dueDate: Date
    public let gestationalAge: GestationalAge
    public let phase: PregnancyPhase
    public let dueDateRelation: DueDateRelation

    public init(
        lastPeriodDate: Date,
        dueDate: Date,
        gestationalAge: GestationalAge,
        phase: PregnancyPhase,
        dueDateRelation: DueDateRelation
    ) {
        self.lastPeriodDate = lastPeriodDate
        self.dueDate = dueDate
        self.gestationalAge = gestationalAge
        self.phase = phase
        self.dueDateRelation = dueDateRelation
    }
}

public struct GestationalAge: Equatable, Sendable {
    public let weeks: Int
    public let days: Int

    public init(weeks: Int, days: Int) {
        self.weeks = weeks
        self.days = days
    }
}

public enum PregnancyPhase: Equatable, Sendable {
    case ongoing
    case lateTerm
    case postTerm
}

public enum DueDateRelation: Equatable, Sendable {
    case upcoming(days: Int)
    case today
    case elapsed(days: Int)
}
