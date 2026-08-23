import AppLocalization
import Foundation
import PregnancyContent
import PregnancyProgress

public struct BabyProgressWidgetSnapshot: Equatable, Sendable {
    public let date: Date
    public let dueDate: Date?
    public let currentWeek: Int
    public let babySizeImageName: String
    public let babySizeLabel: String?
    public let localeIdentifier: String

    public init(
        date: Date,
        dueDate: Date?,
        currentWeek: Int,
        babySizeImageName: String,
        babySizeLabel: String?,
        localeIdentifier: String
    ) {
        self.date = date
        self.dueDate = dueDate
        self.currentWeek = currentWeek
        self.babySizeImageName = babySizeImageName
        self.babySizeLabel = babySizeLabel
        self.localeIdentifier = localeIdentifier
    }
}

public protocol LoadBabyProgressWidgetSnapshotUseCaseProtocol: Sendable {
    func execute(asOf date: Date) async throws -> BabyProgressWidgetSnapshot
}

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
