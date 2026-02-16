import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), eventDate: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let repository = DependencyContainer.shared.repository
        let eventDate = repository.getEventDate() ?? Date()
        let entry = SimpleEntry(date: Date(), eventDate: eventDate)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let repository = DependencyContainer.shared.repository
        let eventDate = repository.getEventDate()
        let entry = SimpleEntry(date: Date(), eventDate: eventDate)
        
        // Refresh every hour or when the app reloads the timeline
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let eventDate: Date?
}

struct BabyProgressWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            if let eventDate = entry.eventDate {
                let days = daysUntil(eventDate)
                
                Text("\(days)")
                    .font(.system(size: 50, weight: .bold))
                    .minimumScaleFactor(0.5)
                Text("days for the big event")
                    .font(.caption)
                    .multilineTextAlignment(.center)
            } else {
                Text("Please set a date in the app")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    func daysUntil(_ date: Date) -> Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfEventDate = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfEventDate)
        return max(0, components.day ?? 0)
    }
}

struct BabyProgressWidget: Widget {
    let kind: String = "BabyProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                BabyProgressWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                BabyProgressWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Days Remaining")
        .description("Count down the days to your big event.")
    }
}

#Preview(as: .systemSmall) {
    BabyProgressWidget()
} timeline: {
    SimpleEntry(date: .now, eventDate: Date().addingTimeInterval(86400 * 5))
}
