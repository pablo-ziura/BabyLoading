@testable import BabyLoading
import Foundation

class MockRepository: BabyProgressRepositoryProtocol {
    var eventDate: Date?
    var daysRemaining: Int?

    var getEventDateCalled = false
    var setEventDateCalled = false
    var daysUntilEventCalled = false
    var getPregnancyWeekCalled = false
    var getCurrentWeekContentCalled = false
    var getAllWeekContentCalled = false
    var currentContentSnapshotCalled = false
    var refreshContentIfNeededCalled = false
    var savePhotoCalled = false
    var fetchPhotoCalled = false
    var deletePhotoCalled = false
    var addPhotoCalled = false
    var fetchAllPhotosCalled = false
    var deletePhotoAtCalled = false

    var pregnancyWeek: Int?
    var currentWeekContent: WeekContent?
    var allWeekContent: [WeekContent] = []
    var contentSnapshot = PregnancyContentDocument.empty
    var refreshContentIfNeededHandler: (() -> Void)?
    var storedPhotoData: Data?
    var storedPhotos: [Data] = []

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

    func getCurrentWeekContent() -> WeekContent? {
        getCurrentWeekContentCalled = true
        return currentWeekContent
    }

    func getAllWeekContent() -> [WeekContent] {
        getAllWeekContentCalled = true
        return allWeekContent
    }

    func currentContentSnapshot() -> PregnancyContentDocument {
        currentContentSnapshotCalled = true
        return contentSnapshot
    }

    func refreshContentIfNeeded() async {
        refreshContentIfNeededCalled = true
        refreshContentIfNeededHandler?()
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

    func addPhoto(data: Data) {
        addPhotoCalled = true
        storedPhotos.append(data)
    }

    func fetchAllPhotos() -> [Data] {
        fetchAllPhotosCalled = true
        return storedPhotos
    }

    func deletePhoto(at index: Int) {
        deletePhotoAtCalled = true
        guard index >= 0 && index < storedPhotos.count else { return }
        storedPhotos.remove(at: index)
    }
}
