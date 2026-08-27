import AppLocalization
import BabyProgressWidgetSupport
import PregnancyProgress
import SwiftUI
import WidgetKit

struct BabyProgressWidget: Widget {
    let kind: String = "BabyProgressWidget"
    private let dependencies = WidgetDependencyContainer()

    var body: some WidgetConfiguration {
        let locale = dependencies.language.locale

        return StaticConfiguration(kind: kind, provider: dependencies.timelineProvider) { entry in
            BabyProgressWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(
            String(localized: "widget.displayName", defaultValue: "Baby Progress", locale: locale)
        )
        .description(
            String(
                localized: "widget.description",
                defaultValue: "See which week of pregnancy you're in.",
                locale: locale
            )
        )
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    BabyProgressWidget()
} timeline: {
    BabyProgressWidgetEntry(
        snapshot: BabyProgressWidgetSnapshot(
            date: .now,
            state: .ongoing(
                progress: BabyProgressWidgetDetails(
                    gestationalAge: GestationalAge(weeks: 20, days: 0),
                    dueDateRelation: .upcoming(days: 5)
                ),
                babySizeImageName: "img_banana",
                babySizeLabel: "a banana"
            ),
            localeIdentifier: AppLanguage.english.rawValue
        )
    )
    BabyProgressWidgetEntry(
        snapshot: BabyProgressWidgetSnapshot(
            date: .now,
            state: .unconfigured,
            localeIdentifier: AppLanguage.english.rawValue
        )
    )
}
