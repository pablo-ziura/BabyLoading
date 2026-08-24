import Foundation

public protocol UpdateLastPeriodDateUseCaseProtocol: Sendable {
    func execute(_ date: Date?) async throws
}
