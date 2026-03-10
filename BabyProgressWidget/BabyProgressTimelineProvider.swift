import Foundation
import WidgetKit

@MainActor
struct BabyProgressTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: .now,
            eventDate: .now,
            week: 40,
            babySize: .pumpkin,
            babySizeLabel: String(localized: "widget.placeholderPumpkinSize", defaultValue: "a pumpkin")
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let repository = DependencyContainer.shared.repository
        let lastPeriodDate = repository.getEventDate()
        let dueDate = lastPeriodDate.map(PregnancyCalculator.calculateDueDate)
        let week = repository.getPregnancyWeek() ?? 0
        let weekContent = repository.getCurrentWeekContent()
        let entry = SimpleEntry(
            date: .now,
            eventDate: dueDate,
            week: week,
            babySize: weekContent?.babySize ?? .unknown,
            babySizeLabel: weekContent?.babySizeLabel ?? String(localized: "widget.unknownSize", defaultValue: "a mystery")
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let repository = DependencyContainer.shared.repository
        let lastPeriodDate = repository.getEventDate()
        let dueDate = lastPeriodDate.map(PregnancyCalculator.calculateDueDate)
        
        print(
            "🔍 [BabyProgressTimelineProvider] getTimeline -> lastPeriod: \(String(describing: lastPeriodDate)), dueDate: \(String(describing: dueDate))"
        )

        let week = repository.getPregnancyWeek() ?? 0
        let weekContent = repository.getCurrentWeekContent()
        let size = weekContent?.babySize ?? .unknown
        print("🔍 [BabyProgressTimelineProvider] getTimeline -> Week: \(week), Size: \(size)")

        let entry = SimpleEntry(
            date: .now,
            eventDate: dueDate,
            week: week,
            babySize: size,
            babySizeLabel: weekContent?.babySizeLabel ?? String(localized: "widget.unknownSize", defaultValue: "a mystery")
        )
        print("✅ [BabyProgressTimelineProvider] Created entry: \(entry)")

        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
