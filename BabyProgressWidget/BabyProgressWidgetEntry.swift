import BabyProgressWidgetSupport
import Foundation
import WidgetKit

struct BabyProgressWidgetEntry: TimelineEntry {
    let snapshot: BabyProgressWidgetSnapshot

    var date: Date {
        snapshot.date
    }
}
