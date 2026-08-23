import Foundation
import WidgetKit

@MainActor
struct BabyProgressTimelineProvider: TimelineProvider {
    private let repository: BabyProgressRepositoryProtocol
    private let language: AppLanguage

    init(
        repository: BabyProgressRepositoryProtocol,
        language: AppLanguage
    ) {
        self.repository = repository
        self.language = language
    }

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: .now,
            eventDate: .now,
            week: 40,
            babySize: .pumpkin,
            babySizeLabel: String(
                localized: "widget.placeholderPumpkinSize",
                defaultValue: "a pumpkin",
                locale: AppLanguage.english.locale
            ),
            languageCode: AppLanguage.english.rawValue
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = makeEntry()

        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func makeEntry() -> SimpleEntry {
        let lastPeriodDate = repository.getEventDate()
        let dueDate = lastPeriodDate.map(PregnancyCalculator.calculateDueDate)
        let week = repository.getPregnancyWeek() ?? 0
        let weekContent = repository.getCurrentWeekContent()

        return SimpleEntry(
            date: .now,
            eventDate: dueDate,
            week: week,
            babySize: weekContent?.babySize ?? .unknown,
            babySizeLabel: weekContent?.babySizeLabel ?? String(
                localized: "widget.unknownSize",
                defaultValue: "a mystery",
                locale: language.locale
            ),
            languageCode: language.rawValue
        )
    }
}
