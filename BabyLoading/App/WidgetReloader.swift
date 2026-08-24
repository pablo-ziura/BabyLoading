import Foundation
import WidgetKit

class DefaultWidgetReloader: WidgetReloaderProtocol {
    func reloadAllTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
