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
        let weekContent: WeekContent?
        if let progress {
            weekContent = await loadPregnancyWeekContentUseCase.execute(week: progress.currentWeek)
        } else {
            weekContent = nil
        }

        return BabyProgressWidgetSnapshot(
            date: date,
            dueDate: progress?.dueDate,
            currentWeek: progress?.currentWeek ?? 0,
            babySizeImageName: (weekContent?.babySize ?? .unknown).imageName,
            babySizeLabel: weekContent?.babySizeLabel,
            localeIdentifier: language.rawValue
        )
    }
}
