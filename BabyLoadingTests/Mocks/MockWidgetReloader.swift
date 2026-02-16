@testable import BabyLoading
import Foundation

class MockWidgetReloader: WidgetReloaderProtocol {
    var reloadAllTimelinesCalled = false

    func reloadAllTimelines() {
        reloadAllTimelinesCalled = true
    }
}
