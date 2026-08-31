import Foundation

public protocol CalculateDueDateUseCaseProtocol: Sendable {
    func execute(lastPeriodDate: Date) -> Date
}
