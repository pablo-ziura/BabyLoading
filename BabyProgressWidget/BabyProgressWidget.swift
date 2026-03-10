import SwiftUI
import WidgetKit

struct BabyProgressWidget: Widget {
    let kind: String = "BabyProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BabyProgressTimelineProvider()) { entry in
            BabyProgressWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(String(localized: "widget.displayName", defaultValue: "Baby Progress"))
        .description(String(localized: "widget.description", defaultValue: "See which week of pregnancy you're in."))
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    BabyProgressWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        eventDate: .now.addingTimeInterval(86400 * 5),
        week: 20,
        babySize: .banana,
        babySizeLabel: "a banana"
    )
    SimpleEntry(
        date: .now,
        eventDate: nil,
        week: 0,
        babySize: .unknown,
        babySizeLabel: String(localized: "widget.unknownSize", defaultValue: "a mystery")
    )
}
