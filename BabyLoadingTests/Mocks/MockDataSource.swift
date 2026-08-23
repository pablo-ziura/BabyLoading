@testable import BabyLoading
import Foundation

class MockDataSource: BabyProgressDataSourceProtocol {
    var storedDate: Date?
    var storedUltrasoundPhotos: [UltrasoundPhoto] = []
    var storedBellyTrackingEntries: [BellyTrackingEntry] = []
    var storedBellyTrackingImages: [String: Data] = [:]
    var storedBellyTrackingSettings = BellyTrackingSettings.default
    var saveCalled = false
    var fetchCalled = false
    var addUltrasoundPhotoCalled = false
    var fetchUltrasoundPhotosCalled = false
    var deleteUltrasoundPhotoCalled = false
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

    func addUltrasoundPhoto(data: Data) {
        addUltrasoundPhotoCalled = true
        storedUltrasoundPhotos.append(UltrasoundPhoto(id: UUID().uuidString, data: data))
    }

    func fetchUltrasoundPhotos() -> [UltrasoundPhoto] {
        fetchUltrasoundPhotosCalled = true
        return storedUltrasoundPhotos
    }

    func deleteUltrasoundPhoto(id: String) {
        deleteUltrasoundPhotoCalled = true
        storedUltrasoundPhotos.removeAll { $0.id == id }
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
