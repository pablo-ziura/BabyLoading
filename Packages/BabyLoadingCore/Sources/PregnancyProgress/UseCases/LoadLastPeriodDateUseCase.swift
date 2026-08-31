import Foundation

public struct LoadLastPeriodDateUseCase: LoadLastPeriodDateUseCaseProtocol, Sendable {
    private let repository: any PregnancyProgressRepositoryProtocol

    public init(repository: any PregnancyProgressRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> Date? {
        try await repository.loadLastPeriodDate()
    }
}
