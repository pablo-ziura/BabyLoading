import AppLocalization
import BabyProgressWidgetSupport
import Foundation
import PregnancyContent
import PregnancyProgress
import Testing

struct BabyProgressWidgetSupportTests {
    @Test func timelineLoadsPersistenceAndContentExactlyOnce() async throws {
        let calendar = try madridCalendar()
        let now = try date(year: 2026, month: 1, day: 7, hour: 23, minute: 45, calendar: calendar)
        let lastPeriodDate = try #require(calendar.date(byAdding: .day, value: -140, to: now))
        let repository = PregnancyProgressRepositoryRecorder(lastPeriodDate: lastPeriodDate)
        let contentUseCase = PregnancyTimelineContentUseCaseRecorder(
            content: [makeWeekContent(week: 20)]
        )
        let contextUseCase = LoadBabyProgressWidgetContextUseCase(
            loadLastPeriodDateUseCase: LoadLastPeriodDateUseCase(repository: repository),
            loadPregnancyTimelineUseCase: contentUseCase,
            language: .english
        )
        let useCase = LoadBabyProgressWidgetTimelineUseCase(
            loadContextUseCase: contextUseCase,
            snapshotFactory: BabyProgressWidgetSnapshotFactory(calendar: calendar),
            calendar: calendar
        )

        let snapshots = try await useCase.execute(asOf: now)

        #expect(snapshots.count == 8)
        #expect(await repository.loadCallCount == 1)
        #expect(await contentUseCase.executionCount == 1)
    }

    @Test func snapshotLoadsOneContextAndCombinesWeeklyContent() async throws {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let calendar = Calendar(identifier: .gregorian)
        let lastPeriodDate = try #require(calendar.date(byAdding: .day, value: -140, to: now))
        let contextUseCase = WidgetContextUseCaseRecorder(
            context: BabyProgressWidgetContext(
                lastPeriodDate: lastPeriodDate,
                weeklyContent: [makeWeekContent(week: 20)],
                language: .english
            )
        )
        let useCase = LoadBabyProgressWidgetSnapshotUseCase(
            loadContextUseCase: contextUseCase,
            snapshotFactory: BabyProgressWidgetSnapshotFactory(calendar: calendar)
        )

        let snapshot = try await useCase.execute(asOf: now)

        #expect(snapshot.state == .ongoing(
            progress: BabyProgressWidgetDetails(
                gestationalAge: GestationalAge(weeks: 20, days: 0),
                dueDateRelation: .upcoming(days: 140)
            ),
            babySizeImageName: "img_sweetpotato",
            babySizeLabel: "a sweet potato"
        ))
        #expect(snapshot.localeIdentifier == "en")
        #expect(await contextUseCase.executionCount == 1)
    }

    @Test func unconfiguredContextProducesOneNonRefreshingSnapshot() async throws {
        let calendar = try madridCalendar()
        let now = try date(year: 2026, month: 1, day: 7, calendar: calendar)
        let context = BabyProgressWidgetContext(
            lastPeriodDate: nil,
            weeklyContent: [],
            language: .spanish
        )
        let snapshots = try await makeTimelineUseCase(context: context, calendar: calendar)
            .execute(asOf: now)

        #expect(snapshots.count == 1)
        #expect(snapshots[0].state == .unconfigured)
        #expect(snapshots[0].localeIdentifier == "es")
    }

    @Test func futureLastPeriodDateProducesOneInvalidSnapshot() async throws {
        let calendar = try madridCalendar()
        let now = try date(year: 2026, month: 1, day: 7, calendar: calendar)
        let futureDate = try #require(calendar.date(byAdding: .day, value: 1, to: now))
        let context = BabyProgressWidgetContext(
            lastPeriodDate: futureDate,
            weeklyContent: [],
            language: .english
        )
        let snapshots = try await makeTimelineUseCase(context: context, calendar: calendar)
            .execute(asOf: now)

        #expect(snapshots.count == 1)
        #expect(snapshots[0].state == .invalidFutureLastPeriodDate)
    }

    @Test func timelinePrecomputesCurrentSnapshotAndSevenFutureMidnights() async throws {
        let calendar = try madridCalendar()
        let now = try date(year: 2026, month: 1, day: 7, hour: 23, minute: 45, calendar: calendar)
        let lastPeriodDate = try #require(calendar.date(byAdding: .day, value: -140, to: now))
        let context = BabyProgressWidgetContext(
            lastPeriodDate: lastPeriodDate,
            weeklyContent: [makeWeekContent(week: 20), makeWeekContent(week: 21)],
            language: .english
        )

        let snapshots = try await makeTimelineUseCase(context: context, calendar: calendar)
            .execute(asOf: now)

        #expect(snapshots.count == 8)
        #expect(snapshots[0].date == now)
        for (index, snapshot) in snapshots.dropFirst().enumerated() {
            let expectedDate = try #require(calendar.date(
                byAdding: .day,
                value: index + 1,
                to: calendar.startOfDay(for: now)
            ))
            #expect(snapshot.date == expectedDate)
        }
    }

    @Test func timelinePreservesLocalMidnightsAcrossDaylightSavingTime() async throws {
        let calendar = try madridCalendar()
        let now = try date(year: 2026, month: 3, day: 28, hour: 23, minute: 45, calendar: calendar)
        let lastPeriodDate = try #require(calendar.date(byAdding: .day, value: -140, to: now))
        let context = BabyProgressWidgetContext(
            lastPeriodDate: lastPeriodDate,
            weeklyContent: [makeWeekContent(week: 20), makeWeekContent(week: 21)],
            language: .english
        )

        let snapshots = try await makeTimelineUseCase(context: context, calendar: calendar)
            .execute(asOf: now)
        let expectedDays = [29, 30, 31, 1, 2, 3, 4]
        let expectedMonths = [3, 3, 3, 4, 4, 4, 4]

        for (index, snapshot) in snapshots.dropFirst().enumerated() {
            let components = calendar.dateComponents([.month, .day, .hour], from: snapshot.date)
            #expect(components.month == expectedMonths[index])
            #expect(components.day == expectedDays[index])
            #expect(components.hour == 0)
        }
    }

    @Test func timelineProjectsLocalizedContentAcrossAWeekBoundary() async throws {
        let calendar = try madridCalendar()
        let now = try date(year: 2026, month: 1, day: 7, hour: 23, minute: 45, calendar: calendar)
        let lastPeriodDate = try #require(calendar.date(byAdding: .day, value: -48, to: now))
        let context = BabyProgressWidgetContext(
            lastPeriodDate: lastPeriodDate,
            weeklyContent: [makeWeekContent(week: 6), makeWeekContent(week: 7)],
            language: .english
        )

        let snapshots = try await makeTimelineUseCase(context: context, calendar: calendar)
            .execute(asOf: now)

        #expect(snapshots[0].ongoingBabySizeLabel == "week 6")
        #expect(snapshots[1].ongoingBabySizeLabel == "week 7")
    }

    @Test(arguments: [
        (287, BabyProgressWidgetState.lateTerm(progress: BabyProgressWidgetDetails(
            gestationalAge: GestationalAge(weeks: 41, days: 0),
            dueDateRelation: .elapsed(days: 7)
        ))),
        (294, BabyProgressWidgetState.postTerm(progress: BabyProgressWidgetDetails(
            gestationalAge: GestationalAge(weeks: 42, days: 0),
            dueDateRelation: .elapsed(days: 14)
        )))
    ])
    func factoryProjectsLateAndPostTermStates(
        elapsedDays: Int,
        expectedState: BabyProgressWidgetState
    ) throws {
        let calendar = try madridCalendar()
        let now = try date(year: 2026, month: 1, day: 7, calendar: calendar)
        let lastPeriodDate = try #require(calendar.date(byAdding: .day, value: -elapsedDays, to: now))
        let context = BabyProgressWidgetContext(
            lastPeriodDate: lastPeriodDate,
            weeklyContent: [],
            language: .english
        )

        let snapshot = BabyProgressWidgetSnapshotFactory(calendar: calendar).makeSnapshot(
            from: context,
            asOf: now
        )

        #expect(snapshot.state == expectedState)
    }

    @Test func contextLoadingFailureIsPropagated() async {
        let useCase = LoadBabyProgressWidgetSnapshotUseCase(
            loadContextUseCase: FailingWidgetContextUseCaseStub(),
            snapshotFactory: BabyProgressWidgetSnapshotFactory(calendar: .current)
        )

        await #expect(throws: WidgetSnapshotTestError.loadFailed) {
            try await useCase.execute(asOf: .now)
        }
    }

    private func makeTimelineUseCase(
        context: BabyProgressWidgetContext,
        calendar: Calendar
    ) -> LoadBabyProgressWidgetTimelineUseCase {
        LoadBabyProgressWidgetTimelineUseCase(
            loadContextUseCase: WidgetContextUseCaseStub(context: context),
            snapshotFactory: BabyProgressWidgetSnapshotFactory(calendar: calendar),
            calendar: calendar
        )
    }

    private func makeWeekContent(week: Int) -> WeekContent {
        WeekContent(
            week: week,
            babySize: .sweetPotato,
            babySizeLabel: week == 20 ? "a sweet potato" : "week \(week)",
            milestoneTitle: "Week \(week)",
            keyEvents: ["Event"],
            physiologicalImpact: nil
        )
    }

    private func madridCalendar() throws -> Calendar {
        let timeZone = try #require(TimeZone(identifier: "Europe/Madrid"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        calendar: Calendar
    ) throws -> Date {
        try #require(calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )))
    }
}

private extension BabyProgressWidgetSnapshot {
    var ongoingBabySizeLabel: String? {
        guard case let .ongoing(_, _, label) = state else { return nil }
        return label
    }
}
