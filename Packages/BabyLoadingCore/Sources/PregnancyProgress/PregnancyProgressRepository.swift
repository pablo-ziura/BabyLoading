import Foundation

public protocol PregnancyProgressRepositoryProtocol: Sendable {
    func loadLastPeriodDate() async throws -> Date?
    func updateLastPeriodDate(_ date: Date?) async throws
}

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

public protocol LoadPregnancyProgressUseCaseProtocol: Sendable {
    func execute(asOf date: Date) async throws -> PregnancyProgress?
}

public struct LoadPregnancyProgressUseCase: LoadPregnancyProgressUseCaseProtocol, Sendable {
    private let repository: any PregnancyProgressRepositoryProtocol
    private let calendar: Calendar

    public init(
        repository: any PregnancyProgressRepositoryProtocol,
        calendar: Calendar
    ) {
        self.repository = repository
        self.calendar = calendar
    }

    public func execute(asOf date: Date) async throws -> PregnancyProgress? {
        guard let lastPeriodDate = try await repository.loadLastPeriodDate() else {
            return nil
        }

        return PregnancyProgress(
            lastPeriodDate: lastPeriodDate,
            dueDate: PregnancyCalculator.calculateDueDate(
                lastPeriod: lastPeriodDate,
                calendar: calendar
            ),
            currentWeek: PregnancyCalculator.currentWeek(
                lastPeriod: lastPeriodDate,
                currentDate: date,
                calendar: calendar
            ),
            daysUntilDueDate: PregnancyCalculator.daysUntilDueDate(
                lastPeriod: lastPeriodDate,
                asOf: date,
                calendar: calendar
            )
        )
    }
}

public protocol UpdateLastPeriodDateUseCaseProtocol: Sendable {
    func execute(_ date: Date?) async throws
}

public struct UpdateLastPeriodDateUseCase: UpdateLastPeriodDateUseCaseProtocol, Sendable {
    private let repository: any PregnancyProgressRepositoryProtocol

    public init(repository: any PregnancyProgressRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(_ date: Date?) async throws {
        try await repository.updateLastPeriodDate(date)
    }
}
