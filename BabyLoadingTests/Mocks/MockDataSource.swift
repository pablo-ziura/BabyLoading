@testable import BabyLoading
import Foundation

class MockDataSource: BabyProgressDataSourceProtocol {
    var storedDate: Date?
    var storedPhotoData: Data?
    var storedPhotos: [Data] = []
    var saveCalled = false
    var fetchCalled = false
    var savePhotoCalled = false
    var fetchPhotoCalled = false
    var deletePhotoCalled = false
    var addPhotoCalled = false
    var fetchAllPhotosCalled = false
    var deletePhotoAtCalled = false

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
