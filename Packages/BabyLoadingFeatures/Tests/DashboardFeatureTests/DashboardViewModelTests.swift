import DashboardFeature
import Foundation
import PregnancyContent
import PregnancyProgress
import Testing

@MainActor
struct DashboardViewModelTests {
    @Test
    func reloadMapsProgressToCurrentWeekContent() async {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let progress = PregnancyProgress(
            lastPeriodDate: date,
            dueDate: date.addingTimeInterval(280 * 86_400),
            currentWeek: 18,
            daysUntilDueDate: 154
        )
        let weekContent = makeWeekContent(week: 18)
        let viewModel = DashboardViewModel(
            loadPregnancyProgressUseCase: DashboardProgressUseCaseStub(progress: progress),
            loadPregnancyWeekContentUseCase: DashboardWeekContentUseCaseStub(content: weekContent)
        )

        await viewModel.reload(asOf: date)

        #expect(viewModel.progress == progress)
        #expect(viewModel.currentWeekContent == weekContent)
        #expect(viewModel.loadingState == .loaded)
    }

    @Test
    func reloadKeepsLastValidContentWhenProgressFails() async {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let progress = PregnancyProgress(
            lastPeriodDate: date,
            dueDate: date,
            currentWeek: 12,
            daysUntilDueDate: 200
        )
        let weekContent = makeWeekContent(week: 12)
        let progressUseCase = DashboardMutableProgressUseCase(progress: progress)
        let viewModel = DashboardViewModel(
            loadPregnancyProgressUseCase: progressUseCase,
            loadPregnancyWeekContentUseCase: DashboardWeekContentUseCaseStub(content: weekContent)
        )

        await viewModel.reload(asOf: date)
        await progressUseCase.setShouldFail(true)
        await viewModel.reload(asOf: date)

        #expect(viewModel.progress == progress)
        #expect(viewModel.currentWeekContent == weekContent)
        #expect(viewModel.loadingState == .failed)
    }

    @Test
    func reloadWithoutStoredProgressClearsCurrentWeekContent() async {
        let viewModel = DashboardViewModel(
            loadPregnancyProgressUseCase: DashboardProgressUseCaseStub(progress: nil),
            loadPregnancyWeekContentUseCase: DashboardWeekContentUseCaseStub(
                content: makeWeekContent(week: 12)
            )
        )

        await viewModel.reload()

        #expect(viewModel.progress == nil)
        #expect(viewModel.currentWeekContent == nil)
        #expect(viewModel.loadingState == .loaded)
    }

    @Test
    func reloadCurrentWeekContentReplacesLocalizationWithoutReloadingProgress() async {
        let progress = PregnancyProgress(
            lastPeriodDate: .now,
            dueDate: .now,
            currentWeek: 18,
            daysUntilDueDate: 154
        )
        let progressUseCase = DashboardProgressUseCaseRecorder(progress: progress)
        let englishContent = makeWeekContent(week: 18, babySizeLabel: "avocado")
        let spanishContent = makeWeekContent(week: 18, babySizeLabel: "aguacate")
        let viewModel = DashboardViewModel(
            loadPregnancyProgressUseCase: progressUseCase,
            loadPregnancyWeekContentUseCase: DashboardWeekContentUseCaseStub(content: englishContent)
        )

        await viewModel.reload()
        await viewModel.reloadCurrentWeekContent(
            using: DashboardWeekContentUseCaseStub(content: spanishContent)
        )

        #expect(viewModel.currentWeekContent == spanishContent)
        #expect(await progressUseCase.executionCount == 1)
    }

    private func makeWeekContent(
        week: Int,
        babySizeLabel: String = "avocado"
    ) -> WeekContent {
        WeekContent(
            week: week,
            babySize: .avocado,
            babySizeLabel: babySizeLabel,
            milestoneTitle: "Milestone",
            keyEvents: ["Event"],
            physiologicalImpact: nil
        )
    }
}

private struct DashboardProgressUseCaseStub: LoadPregnancyProgressUseCaseProtocol {
    let progress: PregnancyProgress?

    func execute(asOf date: Date) async throws -> PregnancyProgress? {
        progress
    }
}

private actor DashboardMutableProgressUseCase: LoadPregnancyProgressUseCaseProtocol {
    private let progress: PregnancyProgress?
    private var shouldFail = false

    init(progress: PregnancyProgress?) {
        self.progress = progress
    }

    func setShouldFail(_ shouldFail: Bool) {
        self.shouldFail = shouldFail
    }

    func execute(asOf date: Date) throws -> PregnancyProgress? {
        if shouldFail {
            throw DashboardTestError.loadFailed
        }
        return progress
    }
}

private actor DashboardProgressUseCaseRecorder: LoadPregnancyProgressUseCaseProtocol {
    private let progress: PregnancyProgress?
    private(set) var executionCount = 0

    init(progress: PregnancyProgress?) {
        self.progress = progress
    }

    func execute(asOf date: Date) -> PregnancyProgress? {
        executionCount += 1
        return progress
    }
}

private struct DashboardWeekContentUseCaseStub: LoadPregnancyWeekContentUseCaseProtocol {
    let content: WeekContent?

    func execute(week: Int) async -> WeekContent? {
        content?.week == week ? content : nil
    }
}

private enum DashboardTestError: Error {
    case loadFailed
}
