import Foundation

public protocol LoadLastPeriodDateUseCaseProtocol: Sendable {
    func execute() async throws -> Date?
}
