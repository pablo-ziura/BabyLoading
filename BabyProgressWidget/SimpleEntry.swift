import Foundation
import PregnancyContent
import WidgetKit

struct SimpleEntry: TimelineEntry {
    let date: Date
    let eventDate: Date?
    let week: Int
    let babySize: BabySize
    let babySizeLabel: String
    let languageCode: String
}
