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
    var savePhotoCalled = false
    var fetchPhotoCalled = false
    var deletePhotoCalled = false

    var pregnancyWeek: Int?
    var babySize: BabySize?
    var storedPhotoData: Data?

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

    func savePhoto(data: Data?) {
        savePhotoCalled = true
        storedPhotoData = data
    }

    func fetchPhoto() -> Data? {
        fetchPhotoCalled = true
        return storedPhotoData
    }

    func deletePhoto() {
        deletePhotoCalled = true
        storedPhotoData = nil
    }
}
