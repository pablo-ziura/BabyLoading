import Foundation

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
