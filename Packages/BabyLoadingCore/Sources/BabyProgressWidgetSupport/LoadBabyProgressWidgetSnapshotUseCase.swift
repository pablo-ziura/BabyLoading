import AppLocalization
import Foundation
import PregnancyContent
import PregnancyProgress

public struct LoadBabyProgressWidgetSnapshotUseCase:
    LoadBabyProgressWidgetSnapshotUseCaseProtocol,
    Sendable {
    private let loadPregnancyProgressUseCase: any LoadPregnancyProgressUseCaseProtocol
    private let loadPregnancyWeekContentUseCase: any LoadPregnancyWeekContentUseCaseProtocol
    private let language: AppLanguage

    public init(
        loadPregnancyProgressUseCase: any LoadPregnancyProgressUseCaseProtocol,
        loadPregnancyWeekContentUseCase: any LoadPregnancyWeekContentUseCaseProtocol,
        language: AppLanguage
    ) {
        self.loadPregnancyProgressUseCase = loadPregnancyProgressUseCase
        self.loadPregnancyWeekContentUseCase = loadPregnancyWeekContentUseCase
        self.language = language
    }

    public func execute(asOf date: Date) async throws -> BabyProgressWidgetSnapshot {
        let progress = try await loadPregnancyProgressUseCase.execute(asOf: date)
        let state: BabyProgressWidgetState

        switch progress {
        case nil:
            state = .unconfigured
        case .invalidFutureLastPeriodDate:
            state = .invalidFutureLastPeriodDate
        case let .active(activeProgress):
            let details = BabyProgressWidgetDetails(
                gestationalAge: activeProgress.gestationalAge,
                dueDateRelation: activeProgress.dueDateRelation
            )

            switch activeProgress.phase {
            case .ongoing:
                let weekContent = await loadPregnancyWeekContentUseCase.execute(
                    week: activeProgress.gestationalAge.weeks
                )
                state = .ongoing(
                    progress: details,
                    babySizeImageName: (weekContent?.babySize ?? .unknown).imageName,
                    babySizeLabel: weekContent?.babySizeLabel
                )
            case .lateTerm:
                state = .lateTerm(progress: details)
            case .postTerm:
                state = .postTerm(progress: details)
            }
        }

        return BabyProgressWidgetSnapshot(
            date: date,
            state: state,
            localeIdentifier: language.rawValue
        )
    }
}
