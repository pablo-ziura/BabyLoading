import Foundation

protocol BabyProgressDataSourceProtocol {
    func save(date: Date?)
    func fetchDate() -> Date?
    func savePhoto(data: Data?)
    func fetchPhoto() -> Data?
    func deletePhoto()

    // Multi-photo support
    func addPhoto(data: Data)
    func fetchAllPhotos() -> [Data]
    func deletePhoto(at index: Int)

    // Belly tracking
    func fetchBellyTrackingEntries() -> [BellyTrackingEntry]
    func fetchBellyTrackingImageData(for imageFileName: String) -> Data?
    func saveBellyTrackingPhoto(data: Data, capturedAt: Date, pregnancyWeekAtCapture: Int?) -> BellyTrackingEntry?
    func deleteBellyTrackingEntry(id: UUID)
    func fetchBellyTrackingSettings() -> BellyTrackingSettings
    func saveBellyTrackingSettings(_ settings: BellyTrackingSettings)
}
