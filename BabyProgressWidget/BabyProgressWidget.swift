import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: BabyProgressConfiguration())
    }

    func snapshot(for configuration: BabyProgressConfiguration, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: BabyProgressConfiguration, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = SimpleEntry(date: Date(), configuration: configuration)
        // Refresh daily as the countdown only changes by day
        let nextUpdate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: BabyProgressConfiguration
}

struct BabyProgressWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            if let eventDate = entry.configuration.eventDate {
                let days = daysUntil(eventDate)
                Text("\(days)")
                    .font(.system(size: 50, weight: .bold))
                    .minimumScaleFactor(0.5)
                Text("days for the big event")
                    .font(.caption)
                    .multilineTextAlignment(.center)
            } else {
                Text("Long press to configure ☝️")
                    .font(.caption)
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
        AppIntentConfiguration(kind: kind, intent: BabyProgressConfiguration.self, provider: Provider()) { entry in
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
    SimpleEntry(date: .now, configuration: BabyProgressConfiguration())
}
