import Foundation

public protocol PregnancyProgressRepositoryProtocol: Sendable {
    func loadLastPeriodDate() async throws -> Date?
    func updateLastPeriodDate(_ date: Date?) async throws
}
