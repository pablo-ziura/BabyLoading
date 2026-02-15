import AppIntents

struct BabyProgressConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Event Date"
    static var description = IntentDescription("Select the date for your big event.")

    @Parameter(title: "Event Date")
    var eventDate: Date?
}
