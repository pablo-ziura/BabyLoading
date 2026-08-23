import AppLocalization
import Foundation

protocol BabyProgressRepositoryProtocol {
    func weekContent(for week: Int) -> WeekContent?
    func getAllWeekContent() -> [WeekContent]
    func currentContentSnapshot() -> PregnancyContentDocument
    func updateContentLanguage(_ language: AppLanguage)
    // Ultrasound gallery
    func addUltrasoundPhoto(data: Data)
    func fetchUltrasoundPhotos() -> [UltrasoundPhoto]
    func deleteUltrasoundPhoto(id: String)

    // Belly tracking
    func fetchBellyTrackingEntries() -> [BellyTrackingEntry]
    func fetchBellyTrackingImageData(for imageFileName: String) -> Data?
    func saveBellyTrackingPhoto(
        data: Data,
        capturedAt: Date,
        pregnancyWeekAtCapture: Int?
    ) -> BellyTrackingEntry?
    func deleteBellyTrackingEntry(id: UUID)
    func fetchBellyTrackingSettings() -> BellyTrackingSettings
    func saveBellyTrackingSettings(_ settings: BellyTrackingSettings)
}
