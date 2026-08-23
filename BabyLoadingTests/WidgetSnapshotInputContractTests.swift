@testable import BabyLoading
import Foundation
import Testing

struct WidgetSnapshotInputContractTests {
    @Test func sharedDateAndWeekContentProvideEveryWidgetSnapshotInput() throws {
        let calendar = Calendar.current
        let lastPeriodDate = try #require(calendar.date(byAdding: .day, value: -140, to: .now))
        let dataSource = MockDataSource()
        dataSource.storedDate = lastPeriodDate
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
        let repository = BabyProgressRepository(
            dataSource: dataSource,
            contentRepository: contentRepository
        )

        let persistedDate = try #require(repository.getEventDate())
        let pregnancyWeek = try #require(repository.getPregnancyWeek())
        let currentWeekContent = try #require(repository.getCurrentWeekContent())

        #expect(persistedDate == lastPeriodDate)
        #expect(PregnancyCalculator.calculateDueDate(lastPeriod: persistedDate) > persistedDate)
        #expect(pregnancyWeek == 20)
        #expect(currentWeekContent.babySize == .sweetPotato)
        #expect(currentWeekContent.babySizeLabel == "a sweet potato")
    }
}
