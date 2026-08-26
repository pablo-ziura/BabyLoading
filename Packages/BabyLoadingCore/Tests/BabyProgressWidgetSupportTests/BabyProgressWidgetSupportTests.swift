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

    @Test func timelinePrecomputesTheCurrentSnapshotAndSevenFutureMidnights() async throws {
        let calendar = try madridCalendar()
        let now = try date(
            year: 2026,
            month: 1,
            day: 7,
            hour: 23,
            minute: 45,
            calendar: calendar
        )
        let dueDate = try date(year: 2026, month: 9, day: 1, calendar: calendar)
        let useCase = LoadBabyProgressWidgetTimelineUseCase(
            loadSnapshotUseCase: ConfiguredWidgetSnapshotUseCaseStub(dueDate: dueDate),
            calendar: calendar
        )

        let snapshots = try await useCase.execute(asOf: now)
        var expectedDates = [now]
        for dayOffset in 1 ... 7 {
            expectedDates.append(try #require(calendar.date(
                byAdding: .day,
                value: dayOffset,
                to: calendar.startOfDay(for: now)
            )))
        }

        #expect(snapshots.count == 8)
        #expect(snapshots.map(\.date) == expectedDates)
    }

    @Test func timelineUsesTheNextWeekContentAtTheCorrespondingMidnight() async throws {
        let calendar = try madridCalendar()
        let now = try date(
            year: 2026,
            month: 1,
            day: 4,
            hour: 23,
            minute: 45,
            calendar: calendar
        )
        let firstWeek33Date = try date(year: 2026, month: 1, day: 5, calendar: calendar)
        let dueDate = try date(year: 2026, month: 3, day: 1, calendar: calendar)
        let useCase = LoadBabyProgressWidgetTimelineUseCase(
            loadSnapshotUseCase: WeekChangingWidgetSnapshotUseCaseStub(
                dueDate: dueDate,
                firstWeek33Date: firstWeek33Date
            ),
            calendar: calendar
        )

        let snapshots = try await useCase.execute(asOf: now)

        #expect(snapshots[0].currentWeek == 32)
        #expect(snapshots[0].babySizeImageName == "img_coconut")
        #expect(snapshots[1].date == firstWeek33Date)
        #expect(snapshots[1].currentWeek == 33)
        #expect(snapshots[1].babySizeImageName == "img_pineapple")
        #expect(snapshots[1].babySizeLabel == "a pineapple")
    }

    @Test func emptyTimelineContainsOnlyTheCurrentSnapshot() async throws {
        let calendar = try madridCalendar()
        let now = try date(
            year: 2026,
            month: 1,
            day: 7,
            hour: 23,
            minute: 45,
            calendar: calendar
        )
        let useCase = LoadBabyProgressWidgetTimelineUseCase(
            loadSnapshotUseCase: EmptyWidgetSnapshotUseCaseStub(),
            calendar: calendar
        )

        let snapshots = try await useCase.execute(asOf: now)

        #expect(snapshots.count == 1)
        #expect(snapshots[0].date == now)
        #expect(snapshots[0].dueDate == nil)
    }

    @Test func timelinePreservesLocalMidnightsAcrossDaylightSavingTime() async throws {
        let calendar = try madridCalendar()
        let now = try date(
            year: 2026,
            month: 3,
            day: 28,
            hour: 23,
            minute: 45,
            calendar: calendar
        )
        let dueDate = try date(year: 2026, month: 9, day: 1, calendar: calendar)
        let useCase = LoadBabyProgressWidgetTimelineUseCase(
            loadSnapshotUseCase: ConfiguredWidgetSnapshotUseCaseStub(dueDate: dueDate),
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

    @Test func timelineLoadingFailureIsPropagated() async throws {
        let useCase = LoadBabyProgressWidgetTimelineUseCase(
            loadSnapshotUseCase: FailingWidgetSnapshotUseCaseStub(),
            calendar: try madridCalendar()
        )

        await #expect(throws: WidgetSnapshotTestError.loadFailed) {
            try await useCase.execute(asOf: .now)
        }
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
        content
    }
}

private struct FailingPregnancyProgressUseCaseStub: LoadPregnancyProgressUseCaseProtocol {
    func execute(asOf date: Date) async throws -> PregnancyProgress? {
        throw WidgetSnapshotTestError.loadFailed
    }
}

private struct ConfiguredWidgetSnapshotUseCaseStub: LoadBabyProgressWidgetSnapshotUseCaseProtocol {
    let dueDate: Date

    func execute(asOf date: Date) async throws -> BabyProgressWidgetSnapshot {
        BabyProgressWidgetSnapshot(
            date: date,
            dueDate: dueDate,
            currentWeek: 32,
            babySizeImageName: "img_coconut",
            babySizeLabel: "a coconut",
            localeIdentifier: "en"
        )
    }
}

private struct WeekChangingWidgetSnapshotUseCaseStub: LoadBabyProgressWidgetSnapshotUseCaseProtocol {
    let dueDate: Date
    let firstWeek33Date: Date

    func execute(asOf date: Date) async throws -> BabyProgressWidgetSnapshot {
        let isWeek33 = date >= firstWeek33Date

        return BabyProgressWidgetSnapshot(
            date: date,
            dueDate: dueDate,
            currentWeek: isWeek33 ? 33 : 32,
            babySizeImageName: isWeek33 ? "img_pineapple" : "img_coconut",
            babySizeLabel: isWeek33 ? "a pineapple" : "a coconut",
            localeIdentifier: "en"
        )
    }
}

private struct EmptyWidgetSnapshotUseCaseStub: LoadBabyProgressWidgetSnapshotUseCaseProtocol {
    func execute(asOf date: Date) async throws -> BabyProgressWidgetSnapshot {
        BabyProgressWidgetSnapshot(
            date: date,
            dueDate: nil,
            currentWeek: 0,
            babySizeImageName: "img_unknown",
            babySizeLabel: nil,
            localeIdentifier: "en"
        )
    }
}

private struct FailingWidgetSnapshotUseCaseStub: LoadBabyProgressWidgetSnapshotUseCaseProtocol {
    func execute(asOf date: Date) async throws -> BabyProgressWidgetSnapshot {
        throw WidgetSnapshotTestError.loadFailed
    }
}

private enum WidgetSnapshotTestError: Error {
    case loadFailed
}
