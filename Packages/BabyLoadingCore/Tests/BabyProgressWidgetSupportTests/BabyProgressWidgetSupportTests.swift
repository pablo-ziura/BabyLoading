import AppLocalization
import BabyProgressWidgetSupport
import Foundation
import PregnancyContent
import PregnancyProgress
import Testing

struct BabyProgressWidgetSupportTests {
    @Test func snapshotCombinesFocusedProgressAndContentOperations() async throws {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let lastPeriodDate = Date(timeIntervalSince1970: 1_000_000)
        let dueDate = Date(timeIntervalSince1970: 3_000_000)
        let progress = PregnancyProgress(
            lastPeriodDate: lastPeriodDate,
            dueDate: dueDate,
            currentWeek: 20,
            daysUntilDueDate: 50
        )
        let weekContent = WeekContent(
            week: 20,
            babySize: .sweetPotato,
            babySizeLabel: "a sweet potato",
            milestoneTitle: "Week 20",
            keyEvents: ["Event"],
            physiologicalImpact: nil
        )
        let useCase = LoadBabyProgressWidgetSnapshotUseCase(
            loadPregnancyProgressUseCase: PregnancyProgressUseCaseStub(progress: progress),
            loadPregnancyWeekContentUseCase: PregnancyWeekContentUseCaseStub(
                content: weekContent
            ),
            language: .english
        )

        let snapshot = try await useCase.execute(asOf: now)

        #expect(snapshot.date == now)
        #expect(snapshot.dueDate == dueDate)
        #expect(snapshot.currentWeek == 20)
        #expect(snapshot.babySizeImageName == "img_sweetpotato")
        #expect(snapshot.babySizeLabel == "a sweet potato")
        #expect(snapshot.localeIdentifier == "en")
    }

    @Test func missingPregnancyDateProducesEmptySnapshot() async throws {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let useCase = LoadBabyProgressWidgetSnapshotUseCase(
            loadPregnancyProgressUseCase: PregnancyProgressUseCaseStub(progress: nil),
            loadPregnancyWeekContentUseCase: PregnancyWeekContentUseCaseStub(content: nil),
            language: .spanish
        )

        let snapshot = try await useCase.execute(asOf: now)

        #expect(snapshot.dueDate == nil)
        #expect(snapshot.currentWeek == 0)
        #expect(snapshot.babySizeImageName == "img_unknown")
        #expect(snapshot.babySizeLabel == nil)
        #expect(snapshot.localeIdentifier == "es")
    }

    @Test func progressLoadingFailureIsPropagated() async {
        let useCase = LoadBabyProgressWidgetSnapshotUseCase(
            loadPregnancyProgressUseCase: FailingPregnancyProgressUseCaseStub(),
            loadPregnancyWeekContentUseCase: PregnancyWeekContentUseCaseStub(content: nil),
            language: .english
        )

        await #expect(throws: WidgetSnapshotTestError.loadFailed) {
            try await useCase.execute(asOf: .now)
        }
    }
}

private struct PregnancyProgressUseCaseStub: LoadPregnancyProgressUseCaseProtocol {
    let progress: PregnancyProgress?

    func execute(asOf date: Date) async throws -> PregnancyProgress? {
        progress
    }
}

private struct PregnancyWeekContentUseCaseStub: LoadPregnancyWeekContentUseCaseProtocol {
    let content: WeekContent?

    func execute(week: Int) async -> WeekContent? {
        content
    }
}

private struct FailingPregnancyProgressUseCaseStub: LoadPregnancyProgressUseCaseProtocol {
    func execute(asOf date: Date) async throws -> PregnancyProgress? {
        throw WidgetSnapshotTestError.loadFailed
    }
}

private enum WidgetSnapshotTestError: Error {
    case loadFailed
}
