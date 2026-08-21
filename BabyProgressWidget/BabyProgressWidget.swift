import SwiftUI
import WidgetKit

struct BabyProgressWidget: Widget {
    let kind: String = "BabyProgressWidget"

    var body: some WidgetConfiguration {
        let locale = AppLanguageRepository().resolvedLanguage().locale

        return StaticConfiguration(kind: kind, provider: BabyProgressTimelineProvider()) { entry in
            BabyProgressWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(String(localized: "widget.displayName", defaultValue: "Baby Progress", locale: locale))
        .description(String(localized: "widget.description", defaultValue: "See which week of pregnancy you're in.", locale: locale))
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
        babySizeLabel: "a banana",
        languageCode: AppLanguage.english.rawValue
    )
    SimpleEntry(
        date: .now,
        eventDate: nil,
        week: 0,
        babySize: .unknown,
        babySizeLabel: String(localized: "widget.unknownSize", defaultValue: "a mystery"),
        languageCode: AppLanguage.english.rawValue
    )
}
