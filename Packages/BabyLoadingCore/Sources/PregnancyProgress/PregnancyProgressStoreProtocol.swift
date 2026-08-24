import Foundation

public protocol PregnancyProgressStoreProtocol: Sendable {
    func loadLastPeriodDate() async throws -> Date?
    func updateLastPeriodDate(_ date: Date?) async throws
}
