import Foundation

public protocol UpdateLastPeriodDateUseCaseProtocol: Sendable {
    func execute(_ date: Date?, asOf: Date) async throws
}
