import Foundation

public struct CalculateDueDateUseCase: CalculateDueDateUseCaseProtocol, Sendable {
    private let calendar: Calendar

    public init(calendar: Calendar) {
        self.calendar = calendar
    }

    public func execute(lastPeriodDate: Date) -> Date {
        PregnancyCalculator.calculateDueDate(lastPeriod: lastPeriodDate, calendar: calendar)
    }
}
