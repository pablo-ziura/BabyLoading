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

        guard !PregnancyCalculator.isFuture(
            lastPeriod: lastPeriodDate,
            asOf: date,
            calendar: calendar
        ) else {
            return .invalidFutureLastPeriodDate(lastPeriodDate: lastPeriodDate)
        }

        let dueDate = PregnancyCalculator.calculateDueDate(
            lastPeriod: lastPeriodDate,
            calendar: calendar
        )
        let gestationalAge = PregnancyCalculator.gestationalAge(
            lastPeriod: lastPeriodDate,
            asOf: date,
            calendar: calendar
        )

        return .active(ActivePregnancyProgress(
            lastPeriodDate: lastPeriodDate,
            dueDate: dueDate,
            gestationalAge: gestationalAge,
            phase: PregnancyCalculator.phase(for: gestationalAge),
            dueDateRelation: PregnancyCalculator.dueDateRelation(
                dueDate: dueDate,
                asOf: date,
                calendar: calendar
            )
        ))
    }
}
