@testable import BabyLoading
import Foundation

class MockDataSource: BabyProgressDataSourceProtocol {
    var storedDate: Date?
    var storedPhotoData: Data?
    var storedPhotos: [Data] = []
    var storedBellyTrackingEntries: [BellyTrackingEntry] = []
    var storedBellyTrackingImages: [String: Data] = [:]
    var storedBellyTrackingSettings = BellyTrackingSettings.default
    var saveCalled = false
    var fetchCalled = false
    var savePhotoCalled = false
    var fetchPhotoCalled = false
    var deletePhotoCalled = false
    var addPhotoCalled = false
    var fetchAllPhotosCalled = false
    var deletePhotoAtCalled = false
    var fetchBellyTrackingEntriesCalled = false
    var fetchBellyTrackingImageDataCalled = false
    var saveBellyTrackingPhotoCalled = false
    var deleteBellyTrackingEntryCalled = false
    var fetchBellyTrackingSettingsCalled = false
    var saveBellyTrackingSettingsCalled = false

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

    func fetchBellyTrackingEntries() -> [BellyTrackingEntry] {
        fetchBellyTrackingEntriesCalled = true
        return storedBellyTrackingEntries
    }

    func fetchBellyTrackingImageData(for imageFileName: String) -> Data? {
        fetchBellyTrackingImageDataCalled = true
        return storedBellyTrackingImages[imageFileName]
    }

    func saveBellyTrackingPhoto(
        data: Data,
        capturedAt: Date,
        pregnancyWeekAtCapture: Int?
    ) -> BellyTrackingEntry? {
        saveBellyTrackingPhotoCalled = true
        let entry = BellyTrackingEntry(
            imageFileName: "\(UUID().uuidString).jpg",
            capturedAt: capturedAt,
            pregnancyWeekAtCapture: pregnancyWeekAtCapture
        )
        storedBellyTrackingEntries.append(entry)
        storedBellyTrackingEntries.sort { $0.capturedAt < $1.capturedAt }
        storedBellyTrackingImages[entry.imageFileName] = data
        storedPhotos.append(data)
        return entry
    }

    func deleteBellyTrackingEntry(id: UUID) {
        deleteBellyTrackingEntryCalled = true
        guard let index = storedBellyTrackingEntries.firstIndex(where: { $0.id == id }) else { return }
        let entry = storedBellyTrackingEntries.remove(at: index)
        storedBellyTrackingImages[entry.imageFileName] = nil
    }

    func fetchBellyTrackingSettings() -> BellyTrackingSettings {
        fetchBellyTrackingSettingsCalled = true
        return storedBellyTrackingSettings
    }

    func saveBellyTrackingSettings(_ settings: BellyTrackingSettings) {
        saveBellyTrackingSettingsCalled = true
        storedBellyTrackingSettings = settings
    }
}
