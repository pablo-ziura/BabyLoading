@testable import BabyLoading
import Foundation
import PregnancyProgress
import Testing

struct WidgetSnapshotInputContractTests {
    @Test func sharedDateAndWeekContentProvideEveryWidgetSnapshotInput() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let lastPeriodDate = try #require(
            ISO8601DateFormatter().date(from: "2026-01-01T00:00:00Z")
        )
        let snapshotDate = try #require(
            calendar.date(byAdding: .day, value: 140, to: lastPeriodDate)
        )
        let progressRepository = WidgetSnapshotProgressRepository(
            lastPeriodDate: lastPeriodDate
        )
        let loadProgressUseCase = LoadPregnancyProgressUseCase(
            repository: progressRepository,
            calendar: calendar
        )
        let dataSource = MockDataSource()
        let contentRepository = MockPregnancyContentRepository()
        let weekContent = WeekContent(
            week: 20,
            babySize: .sweetPotato,
            babySizeLabel: "a sweet potato",
            milestoneTitle: "Week 20",
            keyEvents: ["Growth"],
            physiologicalImpact: "More energy"
        )
        contentRepository.snapshot = PregnancyContentDocument(
            schemaVersion: 1,
            locale: "en",
            revision: 1,
            weeks: [weekContent]
        )
        let contentAndMediaRepository = BabyProgressRepository(
            dataSource: dataSource,
            contentRepository: contentRepository
        )

        let progress = try #require(
            try await loadProgressUseCase.execute(asOf: snapshotDate)
        )
        let currentWeekContent = try #require(
            contentAndMediaRepository.weekContent(for: progress.currentWeek)
        )

        #expect(progress.lastPeriodDate == lastPeriodDate)
        #expect(progress.dueDate > lastPeriodDate)
        #expect(progress.currentWeek == 20)
        #expect(currentWeekContent.babySize == .sweetPotato)
        #expect(currentWeekContent.babySizeLabel == "a sweet potato")
    }
}

private actor WidgetSnapshotProgressRepository: PregnancyProgressRepositoryProtocol {
    private var lastPeriodDate: Date?

    init(lastPeriodDate: Date?) {
        self.lastPeriodDate = lastPeriodDate
    }

    func loadLastPeriodDate() async throws -> Date? {
        lastPeriodDate
    }

    func updateLastPeriodDate(_ date: Date?) async throws {
        lastPeriodDate = date
    }
}
