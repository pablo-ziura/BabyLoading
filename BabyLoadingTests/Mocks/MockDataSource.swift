@testable import BabyLoading
import Foundation

class MockDataSource: BabyProgressDataSourceProtocol {
    var storedDate: Date?
    var storedPhotoData: Data?
    var saveCalled = false
    var fetchCalled = false
    var savePhotoCalled = false
    var fetchPhotoCalled = false
    var deletePhotoCalled = false

    func save(date: Date?) {
        saveCalled = true
        storedDate = date
    }

    func fetchDate() -> Date? {
        fetchCalled = true
        return storedDate
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
