import Foundation

public struct UpdateLastPeriodDateUseCase: UpdateLastPeriodDateUseCaseProtocol, Sendable {
    private let repository: any PregnancyProgressRepositoryProtocol

    public init(repository: any PregnancyProgressRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(_ date: Date?) async throws {
        try await repository.updateLastPeriodDate(date)
    }
}
