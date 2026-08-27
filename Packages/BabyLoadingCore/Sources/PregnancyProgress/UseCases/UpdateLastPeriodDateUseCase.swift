import Foundation

public struct UpdateLastPeriodDateUseCase: UpdateLastPeriodDateUseCaseProtocol, Sendable {
    private let repository: any PregnancyProgressRepositoryProtocol
    private let calendar: Calendar

    public init(
        repository: any PregnancyProgressRepositoryProtocol,
        calendar: Calendar
    ) {
        self.repository = repository
        self.calendar = calendar
    }

    public func execute(_ date: Date?, asOf: Date) async throws {
        if let date, PregnancyCalculator.isFuture(
            lastPeriod: date,
            asOf: asOf,
            calendar: calendar
        ) {
            throw PregnancyProgressValidationError.futureLastPeriodDate
        }

        try await repository.updateLastPeriodDate(date)
    }
}

public enum PregnancyProgressValidationError: Error, Equatable, Sendable {
    case futureLastPeriodDate
}
