import Foundation
import JourneyFeature
import PregnancyContent
import PregnancyProgress
import Testing

@MainActor
struct JourneyViewModelTests {
    @Test
    func reloadProvidesTimelineAndCurrentProgress() async {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let progress = PregnancyProgress(
            lastPeriodDate: date,
            dueDate: date,
            currentWeek: 8,
            daysUntilDueDate: 224
        )
        let timeline = [makeWeekContent(week: 7), makeWeekContent(week: 8)]
        let viewModel = JourneyViewModel(
            loadPregnancyProgressUseCase: JourneyProgressUseCaseStub(progress: progress),
            loadPregnancyTimelineUseCase: JourneyTimelineUseCaseStub(timeline: timeline)
        )

        await viewModel.reload(asOf: date)

        #expect(viewModel.progress == progress)
        #expect(viewModel.pregnancyTimeline == timeline)
        #expect(viewModel.loadingState == .loaded)
    }

    @Test
    func currentDayOffsetUsesCalendarDays() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let lastPeriodDate = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))
        )
        let currentDate = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 1, day: 10))
        )
        let progress = PregnancyProgress(
            lastPeriodDate: lastPeriodDate,
            dueDate: lastPeriodDate,
            currentWeek: 1,
            daysUntilDueDate: 271
        )
        let viewModel = JourneyViewModel(
            loadPregnancyProgressUseCase: JourneyProgressUseCaseStub(progress: progress),
            loadPregnancyTimelineUseCase: JourneyTimelineUseCaseStub(timeline: [])
        )

        await viewModel.reload(asOf: currentDate)

        #expect(viewModel.currentDayOffset(asOf: currentDate, calendar: calendar) == 2)
    }

    @Test
    func reloadFailurePreservesLastValidProgress() async {
        let progress = PregnancyProgress(
            lastPeriodDate: .now,
            dueDate: .now,
            currentWeek: 8,
            daysUntilDueDate: 224
        )
        let progressUseCase = JourneyProgressUseCaseSequenceStub(
            results: [.success(progress), .failure(.loadFailed)]
        )
        let timeline = [makeWeekContent(week: 8)]
        let viewModel = JourneyViewModel(
            loadPregnancyProgressUseCase: progressUseCase,
            loadPregnancyTimelineUseCase: JourneyTimelineUseCaseStub(timeline: timeline)
        )

        await viewModel.reload()
        await viewModel.reload()

        #expect(viewModel.progress == progress)
        #expect(viewModel.pregnancyTimeline == timeline)
        #expect(viewModel.loadingState == .failed)
    }

    @Test
    func reloadContentReplacesTheLocalizedTimeline() async {
        let englishTimeline = [makeWeekContent(week: 7)]
        let spanishTimeline = [makeWeekContent(week: 8)]
        let viewModel = JourneyViewModel(
            loadPregnancyProgressUseCase: JourneyProgressUseCaseStub(progress: nil),
            loadPregnancyTimelineUseCase: JourneyTimelineUseCaseStub(timeline: englishTimeline)
        )

        await viewModel.reload()
        await viewModel.reloadTimeline(
            using: JourneyTimelineUseCaseStub(timeline: spanishTimeline)
        )

        #expect(viewModel.pregnancyTimeline == spanishTimeline)
    }

    private func makeWeekContent(week: Int) -> WeekContent {
        WeekContent(
            week: week,
            babySize: .blueberry,
            babySizeLabel: "blueberry",
            milestoneTitle: "Milestone",
            keyEvents: ["Event"],
            physiologicalImpact: nil
        )
    }
}

private struct JourneyProgressUseCaseStub: LoadPregnancyProgressUseCaseProtocol {
    let progress: PregnancyProgress?

    func execute(asOf date: Date) async throws -> PregnancyProgress? {
        progress
    }
}

private struct JourneyTimelineUseCaseStub: LoadPregnancyTimelineUseCaseProtocol {
    let timeline: [WeekContent]

    func execute() async -> [WeekContent] {
        timeline
    }
}

private actor JourneyProgressUseCaseSequenceStub: LoadPregnancyProgressUseCaseProtocol {
    private var results: [Result<PregnancyProgress?, JourneyProgressError>]

    init(results: [Result<PregnancyProgress?, JourneyProgressError>]) {
        self.results = results
    }

    func execute(asOf date: Date) throws -> PregnancyProgress? {
        try results.removeFirst().get()
    }
}

private enum JourneyProgressError: Error, Sendable {
    case loadFailed
}
