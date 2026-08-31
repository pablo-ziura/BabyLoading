import Foundation
import PregnancyContent
import PregnancyProgress

public protocol BabyProgressWidgetSnapshotFactoryProtocol: Sendable {
    func makeSnapshot(
        from context: BabyProgressWidgetContext,
        asOf date: Date
    ) -> BabyProgressWidgetSnapshot
}

public struct BabyProgressWidgetSnapshotFactory:
    BabyProgressWidgetSnapshotFactoryProtocol,
    Sendable {
    private let calendar: Calendar

    public init(calendar: Calendar) {
        self.calendar = calendar
    }

    public func makeSnapshot(
        from context: BabyProgressWidgetContext,
        asOf date: Date
    ) -> BabyProgressWidgetSnapshot {
        let state = makeState(from: context, asOf: date)
        return BabyProgressWidgetSnapshot(
            date: date,
            state: state,
            localeIdentifier: context.language.rawValue
        )
    }

    private func makeState(
        from context: BabyProgressWidgetContext,
        asOf date: Date
    ) -> BabyProgressWidgetState {
        guard let lastPeriodDate = context.lastPeriodDate else {
            return .unconfigured
        }
        guard !PregnancyCalculator.isFuture(
            lastPeriod: lastPeriodDate,
            asOf: date,
            calendar: calendar
        ) else {
            return .invalidFutureLastPeriodDate
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
        let details = BabyProgressWidgetDetails(
            gestationalAge: gestationalAge,
            dueDateRelation: PregnancyCalculator.dueDateRelation(
                dueDate: dueDate,
                asOf: date,
                calendar: calendar
            )
        )

        switch PregnancyCalculator.phase(for: gestationalAge) {
        case .ongoing:
            let weekContent = context.weeklyContent.first { $0.week == gestationalAge.weeks }
            return .ongoing(
                progress: details,
                babySizeImageName: (weekContent?.babySize ?? .unknown).imageName,
                babySizeLabel: weekContent?.babySizeLabel
            )
        case .lateTerm:
            return .lateTerm(progress: details)
        case .postTerm:
            return .postTerm(progress: details)
        }
    }
}
