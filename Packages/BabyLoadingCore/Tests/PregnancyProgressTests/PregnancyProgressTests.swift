@testable import PregnancyProgress
import AppPreferences
import Foundation
import Testing

struct PregnancyProgressTests {
    @Test func storeReadsLegacyNativeLastPeriodDateValue() async throws {
        let suiteName = "PregnancyProgressTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        userDefaults.removePersistentDomain(forName: suiteName)
        let expectedDate = Date(timeIntervalSince1970: 2_024_040_2)
        userDefaults.set(expectedDate, forKey: "lastPeriodDate")
        let storeUserDefaults = try #require(UserDefaults(suiteName: suiteName))
        let store = PregnancyProgressStore(
            preferencesStore: UserDefaultsPreferencesStore(userDefaults: storeUserDefaults)
        )

        #expect(try await store.loadLastPeriodDate() == expectedDate)
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    @Test func storeWritesEncodedValueAndRemovesCompatibleKey() async throws {
        let suiteName = "PregnancyProgressTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        userDefaults.removePersistentDomain(forName: suiteName)
        let storeUserDefaults = try #require(UserDefaults(suiteName: suiteName))
        let store = PregnancyProgressStore(
            preferencesStore: UserDefaultsPreferencesStore(userDefaults: storeUserDefaults)
        )

        try await store.updateLastPeriodDate(.now)
        #expect(userDefaults.data(forKey: "lastPeriodDate") != nil)

        try await store.updateLastPeriodDate(nil)
        #expect(userDefaults.object(forKey: "lastPeriodDate") == nil)
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    @Test func loadUseCaseBuildsActiveProgressFromCalendarDays() async throws {
        let calendar = utcCalendar()
        let lastPeriodDate = try date(year: 2026, month: 1, day: 1, calendar: calendar)
        let asOfDate = try date(year: 2026, month: 1, day: 22, calendar: calendar)
        let repository = PregnancyProgressRepository(store: InMemoryPregnancyProgressStore())
        let updateUseCase = UpdateLastPeriodDateUseCase(repository: repository, calendar: calendar)
        let loadUseCase = LoadPregnancyProgressUseCase(repository: repository, calendar: calendar)

        try await updateUseCase.execute(lastPeriodDate, asOf: asOfDate)
        let progress = try #require(try await loadUseCase.execute(asOf: asOfDate))

        guard case let .active(activeProgress) = progress else {
            Issue.record("Expected active progress")
            return
        }

        #expect(activeProgress.lastPeriodDate == lastPeriodDate)
        #expect(activeProgress.gestationalAge == GestationalAge(weeks: 3, days: 0))
        #expect(activeProgress.phase == .ongoing)
        #expect(activeProgress.dueDateRelation == .upcoming(days: 259))
    }

    @Test func dueDateUsesExactly280CalendarDays() throws {
        let calendar = utcCalendar()
        let lastPeriodDate = try date(year: 2026, month: 3, day: 1, calendar: calendar)
        let expectedDueDate = try date(year: 2026, month: 12, day: 6, calendar: calendar)

        #expect(PregnancyCalculator.calculateDueDate(
            lastPeriod: lastPeriodDate,
            calendar: calendar
        ) == expectedDueDate)
    }

    @Test(arguments: [
        (279, GestationalAge(weeks: 39, days: 6), PregnancyPhase.ongoing),
        (280, GestationalAge(weeks: 40, days: 0), PregnancyPhase.ongoing),
        (286, GestationalAge(weeks: 40, days: 6), PregnancyPhase.ongoing),
        (287, GestationalAge(weeks: 41, days: 0), PregnancyPhase.lateTerm),
        (293, GestationalAge(weeks: 41, days: 6), PregnancyPhase.lateTerm),
        (294, GestationalAge(weeks: 42, days: 0), PregnancyPhase.postTerm)
    ])
    func phaseUsesClinicalDayBoundaries(
        elapsedDays: Int,
        expectedAge: GestationalAge,
        expectedPhase: PregnancyPhase
    ) throws {
        let calendar = utcCalendar()
        let lastPeriodDate = try date(year: 2026, month: 1, day: 1, calendar: calendar)
        let asOfDate = try #require(calendar.date(
            byAdding: .day,
            value: elapsedDays,
            to: lastPeriodDate
        ))
        let gestationalAge = PregnancyCalculator.gestationalAge(
            lastPeriod: lastPeriodDate,
            asOf: asOfDate,
            calendar: calendar
        )

        #expect(gestationalAge == expectedAge)
        #expect(PregnancyCalculator.phase(for: gestationalAge) == expectedPhase)
    }

    @Test func dueDateRelationPreservesElapsedDays() throws {
        let calendar = utcCalendar()
        let dueDate = try date(year: 2026, month: 10, day: 8, calendar: calendar)
        let dayBefore = try #require(calendar.date(byAdding: .day, value: -1, to: dueDate))
        let dayAfter = try #require(calendar.date(byAdding: .day, value: 1, to: dueDate))

        #expect(PregnancyCalculator.dueDateRelation(
            dueDate: dueDate,
            asOf: dayBefore,
            calendar: calendar
        ) == .upcoming(days: 1))
        #expect(PregnancyCalculator.dueDateRelation(
            dueDate: dueDate,
            asOf: dueDate,
            calendar: calendar
        ) == .today)
        #expect(PregnancyCalculator.dueDateRelation(
            dueDate: dueDate,
            asOf: dayAfter,
            calendar: calendar
        ) == .elapsed(days: 1))
    }

    @Test func loadUseCaseReturnsAnInvalidStateForHistoricalFutureDate() async throws {
        let calendar = utcCalendar()
        let asOfDate = try date(year: 2026, month: 1, day: 1, calendar: calendar)
        let futureDate = try date(year: 2026, month: 1, day: 2, calendar: calendar)
        let store = InMemoryPregnancyProgressStore(initialDate: futureDate)
        let repository = PregnancyProgressRepository(store: store)
        let useCase = LoadPregnancyProgressUseCase(repository: repository, calendar: calendar)

        let progress = try #require(try await useCase.execute(asOf: asOfDate))

        #expect(progress == .invalidFutureLastPeriodDate(lastPeriodDate: futureDate))
    }

    @Test func updateUseCaseRejectsFutureDatesAndPersistsToday() async throws {
        let calendar = utcCalendar()
        let asOfDate = try date(year: 2026, month: 1, day: 1, calendar: calendar)
        let futureDate = try date(year: 2026, month: 1, day: 2, calendar: calendar)
        let store = InMemoryPregnancyProgressStore()
        let repository = PregnancyProgressRepository(store: store)
        let useCase = UpdateLastPeriodDateUseCase(repository: repository, calendar: calendar)

        await #expect(throws: PregnancyProgressValidationError.futureLastPeriodDate) {
            try await useCase.execute(futureDate, asOf: asOfDate)
        }
        #expect(await store.loadLastPeriodDate() == nil)

        try await useCase.execute(asOfDate, asOf: asOfDate)
        #expect(await store.loadLastPeriodDate() == asOfDate)
    }

    @Test func calendarDayCalculationsSurviveDaylightSavingTime() throws {
        let timeZone = try #require(TimeZone(identifier: "Europe/Madrid"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let lastPeriodDate = try date(year: 2026, month: 3, day: 28, calendar: calendar)
        let asOfDate = try date(year: 2026, month: 3, day: 29, calendar: calendar)

        #expect(PregnancyCalculator.gestationalAge(
            lastPeriod: lastPeriodDate,
            asOf: asOfDate,
            calendar: calendar
        ) == GestationalAge(weeks: 0, days: 1))
    }

    @Test func loadUseCaseReturnsNilWithoutStoredDate() async throws {
        let repository = PregnancyProgressRepository(store: InMemoryPregnancyProgressStore())
        let useCase = LoadPregnancyProgressUseCase(repository: repository, calendar: utcCalendar())

        #expect(try await useCase.execute(asOf: .now) == nil)
    }

    @Test func updateUseCaseRemovesStoredDate() async throws {
        let calendar = utcCalendar()
        let store = InMemoryPregnancyProgressStore()
        let repository = PregnancyProgressRepository(store: store)
        let updateUseCase = UpdateLastPeriodDateUseCase(repository: repository, calendar: calendar)
        let loadUseCase = LoadPregnancyProgressUseCase(repository: repository, calendar: calendar)
        let asOfDate = try date(year: 2026, month: 1, day: 1, calendar: calendar)

        try await updateUseCase.execute(asOfDate, asOf: asOfDate)
        try await updateUseCase.execute(nil, asOf: asOfDate)

        #expect(try await loadUseCase.execute(asOf: asOfDate) == nil)
    }

    @Test func useCasesPropagateStoreFailures() async {
        let calendar = utcCalendar()
        let repository = PregnancyProgressRepository(store: FailingPregnancyProgressStore())
        let loadUseCase = LoadPregnancyProgressUseCase(repository: repository, calendar: calendar)
        let updateUseCase = UpdateLastPeriodDateUseCase(repository: repository, calendar: calendar)

        await #expect(throws: PregnancyProgressTestError.self) {
            try await loadUseCase.execute(asOf: .now)
        }
        await #expect(throws: PregnancyProgressTestError.self) {
            try await updateUseCase.execute(.now, asOf: .now)
        }
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
        return calendar
    }

    private func date(year: Int, month: Int, day: Int, calendar: Calendar) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day)))
    }
}

private enum PregnancyProgressTestError: Error {
    case unavailable
}

private actor FailingPregnancyProgressStore: PregnancyProgressStoreProtocol {
    func loadLastPeriodDate() throws -> Date? {
        throw PregnancyProgressTestError.unavailable
    }

    func updateLastPeriodDate(_ date: Date?) throws {
        throw PregnancyProgressTestError.unavailable
    }
}

private actor InMemoryPregnancyProgressStore: PregnancyProgressStoreProtocol {
    private var date: Date?

    init(initialDate: Date? = nil) {
        date = initialDate
    }

    func loadLastPeriodDate() -> Date? {
        date
    }

    func updateLastPeriodDate(_ date: Date?) {
        self.date = date
    }
}
