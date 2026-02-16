import Foundation
import WidgetKit

struct BabyProgressTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .now, eventDate: .now, week: 40, babySize: .pumpkin)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let repository = DependencyContainer.shared.repository
        let eventDate = repository.getEventDate() ?? .now
        let week = repository.getPregnancyWeek() ?? 0
        let size = repository.getBabySize() ?? .unknown
        let entry = SimpleEntry(date: .now, eventDate: eventDate, week: week, babySize: size)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let repository = DependencyContainer.shared.repository
        let eventDate = repository.getEventDate()
        let week = repository.getPregnancyWeek() ?? 0
        let size = repository.getBabySize() ?? .unknown
        let entry = SimpleEntry(date: .now, eventDate: eventDate, week: week, babySize: size)

        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
