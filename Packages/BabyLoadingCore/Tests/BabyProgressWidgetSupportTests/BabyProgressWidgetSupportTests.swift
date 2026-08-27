import AppLocalization
import BabyProgressWidgetSupport
import Foundation
import PregnancyContent
import PregnancyProgress
import Testing

struct BabyProgressWidgetSupportTests {
    @Test func ongoingSnapshotCombinesProgressAndWeeklyContent() async throws {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let activeProgress = makeActiveProgress(weeks: 20, days: 0, phase: .ongoing)
        let useCase = LoadBabyProgressWidgetSnapshotUseCase(
            loadPregnancyProgressUseCase: PregnancyProgressUseCaseStub(progress: .active(activeProgress)),
            loadPregnancyWeekContentUseCase: PregnancyWeekContentUseCaseStub(
                content: makeWeekContent(week: 20)
            ),
            language: .english
        )

        let snapshot = try await useCase.execute(asOf: now)

        #expect(snapshot.date == now)
        #expect(snapshot.state == .ongoing(
            progress: BabyProgressWidgetDetails(
                gestationalAge: GestationalAge(weeks: 20, days: 0),
                dueDateRelation: .upcoming(days: 140)
            ),
            babySizeImageName: "img_sweetpotato",
            babySizeLabel: "a sweet potato"
        ))
        #expect(snapshot.localeIdentifier == "en")
    }

    @Test func missingPregnancyDateProducesUnconfiguredSnapshot() async throws {
        let useCase = LoadBabyProgressWidgetSnapshotUseCase(
            loadPregnancyProgressUseCase: PregnancyProgressUseCaseStub(progress: nil),
            loadPregnancyWeekContentUseCase: PregnancyWeekContentUseCaseStub(content: nil),
            language: .spanish
        )

        let snapshot = try await useCase.execute(asOf: .now)

        #expect(snapshot.state == .unconfigured)
        #expect(snapshot.requiresDailyTimelineRefresh == false)
        #expect(snapshot.localeIdentifier == "es")
    }

    @Test func futureLastPeriodDateProducesInvalidSnapshot() async throws {
        let useCase = LoadBabyProgressWidgetSnapshotUseCase(
            loadPregnancyProgressUseCase: PregnancyProgressUseCaseStub(
                progress: .invalidFutureLastPeriodDate(lastPeriodDate: .now)
            ),
            loadPregnancyWeekContentUseCase: PregnancyWeekContentUseCaseStub(content: nil),
            language: .english
        )

        let snapshot = try await useCase.execute(asOf: .now)

        #expect(snapshot.state == .invalidFutureLastPeriodDate)
        #expect(snapshot.requiresDailyTimelineRefresh == false)
    }

    @Test func lateAndPostTermSnapshotsDoNotRequestWeeklyContent() async throws {
        let contentUseCase = PregnancyWeekContentUseCaseRecorder()
        let lateTermUseCase = LoadBabyProgressWidgetSnapshotUseCase(
            loadPregnancyProgressUseCase: PregnancyProgressUseCaseStub(
                progress: .active(makeActiveProgress(weeks: 41, days: 0, phase: .lateTerm))
            ),
            loadPregnancyWeekContentUseCase: contentUseCase,
            language: .english
        )
        let postTermUseCase = LoadBabyProgressWidgetSnapshotUseCase(
            loadPregnancyProgressUseCase: PregnancyProgressUseCaseStub(
                progress: .active(makeActiveProgress(weeks: 42, days: 0, phase: .postTerm))
            ),
            loadPregnancyWeekContentUseCase: contentUseCase,
            language: .english
        )

        let lateTermSnapshot = try await lateTermUseCase.execute(asOf: .now)
        let postTermSnapshot = try await postTermUseCase.execute(asOf: .now)

        #expect(lateTermSnapshot.state == .lateTerm(progress: BabyProgressWidgetDetails(
            gestationalAge: GestationalAge(weeks: 41, days: 0),
            dueDateRelation: .elapsed(days: 7)
        )))
        #expect(postTermSnapshot.state == .postTerm(progress: BabyProgressWidgetDetails(
            gestationalAge: GestationalAge(weeks: 42, days: 0),
            dueDateRelation: .elapsed(days: 14)
        )))
        #expect(await contentUseCase.executionCount == 0)
    }

    @Test func timelinePrecomputesActiveCurrentSnapshotAndSevenFutureMidnights() async throws {
        let calendar = try madridCalendar()
        let now = try date(year: 2026, month: 1, day: 7, hour: 23, minute: 45, calendar: calendar)
        let useCase = LoadBabyProgressWidgetTimelineUseCase(
            loadSnapshotUseCase: ConfiguredWidgetSnapshotUseCaseStub(),
            calendar: calendar
        )

        let snapshots = try await useCase.execute(asOf: now)

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

    @Test func timelineContainsOnlyCurrentSnapshotForNonRefreshingStates() async throws {
        let calendar = try madridCalendar()
        let now = try date(year: 2026, month: 1, day: 7, hour: 23, minute: 45, calendar: calendar)
        let useCase = LoadBabyProgressWidgetTimelineUseCase(
            loadSnapshotUseCase: InvalidWidgetSnapshotUseCaseStub(),
            calendar: calendar
        )

        let snapshots = try await useCase.execute(asOf: now)

        #expect(snapshots.count == 1)
        #expect(snapshots[0].state == .invalidFutureLastPeriodDate)
    }

    @Test func timelinePreservesLocalMidnightsAcrossDaylightSavingTime() async throws {
        let calendar = try madridCalendar()
        let now = try date(year: 2026, month: 3, day: 28, hour: 23, minute: 45, calendar: calendar)
        let useCase = LoadBabyProgressWidgetTimelineUseCase(
            loadSnapshotUseCase: ConfiguredWidgetSnapshotUseCaseStub(),
            calendar: calendar
        )

        let snapshots = try await useCase.execute(asOf: now)
        let expectedDays = [29, 30, 31, 1, 2, 3, 4]
        let expectedMonths = [3, 3, 3, 4, 4, 4, 4]

        for (index, snapshot) in snapshots.dropFirst().enumerated() {
            let components = calendar.dateComponents([.month, .day, .hour], from: snapshot.date)

            #expect(components.month == expectedMonths[index])
            #expect(components.day == expectedDays[index])
            #expect(components.hour == 0)
        }
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

    private func makeActiveProgress(
        weeks: Int,
        days: Int,
        phase: PregnancyPhase
    ) -> ActivePregnancyProgress {
        let elapsedDays = phase == .ongoing ? 140 : (phase == .lateTerm ? 7 : 14)
        return ActivePregnancyProgress(
            lastPeriodDate: Date(timeIntervalSince1970: 1_000_000),
            dueDate: Date(timeIntervalSince1970: 3_000_000),
            gestationalAge: GestationalAge(weeks: weeks, days: days),
            phase: phase,
            dueDateRelation: phase == .ongoing ? .upcoming(days: elapsedDays) : .elapsed(days: elapsedDays)
        )
    }

    private func makeWeekContent(week: Int) -> WeekContent {
        WeekContent(
            week: week,
            babySize: .sweetPotato,
            babySizeLabel: "a sweet potato",
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

private struct PregnancyProgressUseCaseStub: LoadPregnancyProgressUseCaseProtocol {
    let progress: PregnancyProgress?

    func execute(asOf date: Date) async throws -> PregnancyProgress? {
        progress
    }
}

private struct PregnancyWeekContentUseCaseStub: LoadPregnancyWeekContentUseCaseProtocol {
    let content: WeekContent?

    func execute(week: Int) async -> WeekContent? {
        content?.week == week ? content : nil
    }
}

private actor PregnancyWeekContentUseCaseRecorder: LoadPregnancyWeekContentUseCaseProtocol {
    private(set) var executionCount = 0

    func execute(week: Int) -> WeekContent? {
        executionCount += 1
        return nil
    }
}

private struct FailingPregnancyProgressUseCaseStub: LoadPregnancyProgressUseCaseProtocol {
    func execute(asOf date: Date) async throws -> PregnancyProgress? {
        throw WidgetSnapshotTestError.loadFailed
    }
}

private struct ConfiguredWidgetSnapshotUseCaseStub: LoadBabyProgressWidgetSnapshotUseCaseProtocol {
    func execute(asOf date: Date) async throws -> BabyProgressWidgetSnapshot {
        BabyProgressWidgetSnapshot(
            date: date,
            state: .ongoing(
                progress: BabyProgressWidgetDetails(
                    gestationalAge: GestationalAge(weeks: 32, days: 0),
                    dueDateRelation: .upcoming(days: 56)
                ),
                babySizeImageName: "img_coconut",
                babySizeLabel: "a coconut"
            ),
            localeIdentifier: "en"
        )
    }
}

private struct InvalidWidgetSnapshotUseCaseStub: LoadBabyProgressWidgetSnapshotUseCaseProtocol {
    func execute(asOf date: Date) async throws -> BabyProgressWidgetSnapshot {
        BabyProgressWidgetSnapshot(
            date: date,
            state: .invalidFutureLastPeriodDate,
            localeIdentifier: "en"
        )
    }
}

private enum WidgetSnapshotTestError: Error {
    case loadFailed
}
