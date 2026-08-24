import Foundation

public actor PregnancyProgressRepository: PregnancyProgressRepositoryProtocol {
    private let store: any PregnancyProgressStoreProtocol

    public init(store: any PregnancyProgressStoreProtocol) {
        self.store = store
    }

    public func loadLastPeriodDate() async throws -> Date? {
        try await store.loadLastPeriodDate()
    }

    public func updateLastPeriodDate(_ date: Date?) async throws {
        try await store.updateLastPeriodDate(date)
    }
}
