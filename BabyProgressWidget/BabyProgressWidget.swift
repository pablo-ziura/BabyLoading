import SwiftUI
import WidgetKit

struct BabyProgressWidget: Widget {
    let kind: String = "BabyProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BabyProgressTimelineProvider()) { entry in
                BabyProgressWidgetEntryView(entry: entry)
                    .padding()
                    .background()
        }
        .configurationDisplayName("Days Remaining")
        .description("Count down the days to your big event.")
    }
}

#Preview(as: .systemSmall) {
    BabyProgressWidget()
} timeline: {
    SimpleEntry(date: .now, eventDate: .now.addingTimeInterval(86400 * 5), week: 20, babySize: .banana)
}
