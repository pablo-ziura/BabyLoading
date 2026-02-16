@testable import BabyLoading
import Foundation

class MockRepository: BabyProgressRepositoryProtocol {
    var eventDate: Date?
    var daysRemaining: Int?

    var getEventDateCalled = false
    var setEventDateCalled = false
    var daysUntilEventCalled = false
    var getPregnancyWeekCalled = false
    var getBabySizeCalled = false

    var pregnancyWeek: Int?
    var babySize: BabySize?

    func getEventDate() -> Date? {
        getEventDateCalled = true
        return eventDate
    }

    func setEventDate(_ date: Date?) {
        setEventDateCalled = true
        eventDate = date
    }

    func daysUntilEvent() -> Int? {
        daysUntilEventCalled = true
        return daysRemaining
    }

    func getPregnancyWeek() -> Int? {
        getPregnancyWeekCalled = true
        return pregnancyWeek
    }

    func getBabySize() -> BabySize? {
        getBabySizeCalled = true
        return babySize
    }
}
