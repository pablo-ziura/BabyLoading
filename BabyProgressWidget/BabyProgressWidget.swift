import SwiftUI
import WidgetKit

struct BabyProgressWidget: Widget {
    let kind: String = "BabyProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BabyProgressTimelineProvider()) { entry in
            BabyProgressWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Baby Progress")
        .description("Mira en qué semana del embarazo estás.")
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    BabyProgressWidget()
} timeline: {
    SimpleEntry(date: .now, eventDate: .now.addingTimeInterval(86400 * 5), week: 20, babySize: .banana)
    SimpleEntry(date: .now, eventDate: nil, week: 0, babySize: .unknown)
}
