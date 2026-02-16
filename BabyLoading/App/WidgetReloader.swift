import Foundation
import WidgetKit

protocol WidgetReloaderProtocol {
    func reloadAllTimelines()
}

class DefaultWidgetReloader: WidgetReloaderProtocol {
    func reloadAllTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
