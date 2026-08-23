@testable import BabyLoading
import Foundation

class MockRepository: BabyProgressRepositoryProtocol {
    var fetchBellyTrackingEntriesCalled = false
    var fetchBellyTrackingImageDataCalled = false
    var saveBellyTrackingPhotoCalled = false
    var deleteBellyTrackingEntryCalled = false
    var fetchBellyTrackingSettingsCalled = false
    var saveBellyTrackingSettingsCalled = false

    var storedBellyTrackingEntries: [BellyTrackingEntry] = []
    var storedBellyTrackingImages: [String: Data] = [:]
    var storedBellyTrackingSettings = BellyTrackingSettings.default

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
