import Foundation
import WidgetKit

struct BabyProgressTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .now, eventDate: .now, week: 40, babySize: .pumpkin)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let repository = DependencyContainer.shared.repository
        let lastPeriodDate = repository.getEventDate() ?? .now
        let dueDate = PregnancyCalculator.calculateDueDate(lastPeriod: lastPeriodDate)
        let week = repository.getPregnancyWeek() ?? 0
        let size = repository.getBabySize() ?? .unknown
        let entry = SimpleEntry(date: .now, eventDate: dueDate, week: week, babySize: size)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let repository = DependencyContainer.shared.repository
        let lastPeriodDate = repository.getEventDate() ?? .now
        let dueDate = PregnancyCalculator.calculateDueDate(lastPeriod: lastPeriodDate)
        
        print("🔍 [BabyProgressTimelineProvider] getTimeline -> lastPeriod: \(lastPeriodDate), dueDate: \(dueDate)")

        let week = repository.getPregnancyWeek() ?? 0
        let size = repository.getBabySize() ?? .unknown
        print("🔍 [BabyProgressTimelineProvider] getTimeline -> Week: \(week), Size: \(size)")

        let entry = SimpleEntry(date: .now, eventDate: dueDate, week: week, babySize: size)
        print("✅ [BabyProgressTimelineProvider] Created entry: \(entry)")

        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
