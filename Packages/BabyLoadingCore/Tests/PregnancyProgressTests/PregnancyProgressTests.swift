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

        let storedDate = try await store.loadLastPeriodDate()

        #expect(PregnancyProgressStore.lastPeriodDateKey.name == "lastPeriodDate")
        #expect(storedDate == expectedDate)
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

    @Test func updateAndLoadUseCasesShareFocusedRepository() async throws {
        let store = InMemoryPregnancyProgressStore()
        let repository = PregnancyProgressRepository(store: store)
        let updateUseCase = UpdateLastPeriodDateUseCase(repository: repository)
        let calendar = utcCalendar()
        let loadUseCase = LoadPregnancyProgressUseCase(
            repository: repository,
            calendar: calendar
        )
        let lastPeriodDate = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 1,
            day: 1
        )))
        let currentDate = try #require(calendar.date(
            byAdding: .day,
            value: 21,
            to: lastPeriodDate
        ))

        try await updateUseCase.execute(lastPeriodDate)
        let progress = try #require(try await loadUseCase.execute(asOf: currentDate))

        #expect(progress.lastPeriodDate == lastPeriodDate)
        #expect(progress.currentWeek == 3)
        #expect(progress.daysUntilDueDate > 0)
    }

    @Test func loadUseCaseReturnsNilWithoutStoredDate() async throws {
        let repository = PregnancyProgressRepository(store: InMemoryPregnancyProgressStore())
        let useCase = LoadPregnancyProgressUseCase(
            repository: repository,
            calendar: utcCalendar()
        )

        let progress = try await useCase.execute(asOf: .now)

        #expect(progress == nil)
    }

    @Test func updateUseCaseRemovesStoredDate() async throws {
        let store = InMemoryPregnancyProgressStore()
        let repository = PregnancyProgressRepository(store: store)
        let updateUseCase = UpdateLastPeriodDateUseCase(repository: repository)
        let loadUseCase = LoadPregnancyProgressUseCase(
            repository: repository,
            calendar: utcCalendar()
        )

        try await updateUseCase.execute(.now)
        try await updateUseCase.execute(nil)

        #expect(try await loadUseCase.execute(asOf: .now) == nil)
    }

    @Test func calculatorUsesCalendarDaysAndClampsPastDueDate() throws {
        let calendar = utcCalendar()
        let lastPeriodDate = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 1,
            day: 1
        )))
        let expectedDueDate = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 10,
            day: 8
        )))
        let dateAfterDueDate = try #require(calendar.date(
            byAdding: .day,
            value: 1,
            to: expectedDueDate
        ))

        #expect(PregnancyCalculator.calculateDueDate(
            lastPeriod: lastPeriodDate,
            calendar: calendar
        ) == expectedDueDate)
        #expect(PregnancyCalculator.currentWeek(
            lastPeriod: lastPeriodDate,
            currentDate: expectedDueDate,
            calendar: calendar
        ) == 40)
        #expect(PregnancyCalculator.daysUntilDueDate(
            lastPeriod: lastPeriodDate,
            asOf: dateAfterDueDate,
            calendar: calendar
        ) == 0)
    }

    @Test func useCasesPropagateStoreFailures() async {
        let repository = PregnancyProgressRepository(store: FailingPregnancyProgressStore())
        let loadUseCase = LoadPregnancyProgressUseCase(
            repository: repository,
            calendar: utcCalendar()
        )
        let updateUseCase = UpdateLastPeriodDateUseCase(repository: repository)

        await #expect(throws: PregnancyProgressTestError.self) {
            try await loadUseCase.execute(asOf: .now)
        }
        await #expect(throws: PregnancyProgressTestError.self) {
            try await updateUseCase.execute(.now)
        }
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
        return calendar
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

    func loadLastPeriodDate() -> Date? {
        date
    }

    func updateLastPeriodDate(_ date: Date?) {
        self.date = date
    }
}
