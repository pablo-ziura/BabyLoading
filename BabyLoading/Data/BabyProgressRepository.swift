import Foundation

class BabyProgressRepository: BabyProgressRepositoryProtocol {
    private let dataSource: BabyProgressDataSourceProtocol

    init(dataSource: BabyProgressDataSourceProtocol) {
        self.dataSource = dataSource
    }

    // MARK: - Ultrasound gallery

    func addUltrasoundPhoto(data: Data) {
        dataSource.addUltrasoundPhoto(data: data)
    }

    func fetchUltrasoundPhotos() -> [UltrasoundPhoto] {
        dataSource.fetchUltrasoundPhotos()
    }

    func deleteUltrasoundPhoto(id: String) {
        dataSource.deleteUltrasoundPhoto(id: id)
    }

    // MARK: - Belly tracking

    func fetchBellyTrackingEntries() -> [BellyTrackingEntry] {
        dataSource.fetchBellyTrackingEntries()
    }

    func fetchBellyTrackingImageData(for imageFileName: String) -> Data? {
        dataSource.fetchBellyTrackingImageData(for: imageFileName)
    }

    func saveBellyTrackingPhoto(
        data: Data,
        capturedAt: Date,
        pregnancyWeekAtCapture: Int?
    ) -> BellyTrackingEntry? {
        dataSource.saveBellyTrackingPhoto(
            data: data,
            capturedAt: capturedAt,
            pregnancyWeekAtCapture: pregnancyWeekAtCapture
        )
    }

    func deleteBellyTrackingEntry(id: UUID) {
        dataSource.deleteBellyTrackingEntry(id: id)
    }

    func fetchBellyTrackingSettings() -> BellyTrackingSettings {
        dataSource.fetchBellyTrackingSettings()
    }

    func saveBellyTrackingSettings(_ settings: BellyTrackingSettings) {
        dataSource.saveBellyTrackingSettings(settings)
    }

}
