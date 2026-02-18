import Foundation
import Observation

@Observable
class BabyProgressViewModel {
    var lastPeriodDate: Date
    var estimatedDueDate: Date?
    var daysRemaining: Int?
    var pregnancyWeek: Int?
    var babySizeString: String?
    var currentBabySize: BabySize?
    var photoData: Data?
    var photosData: [Data] = []
    var showingPhotoPicker = false

    private let repository: BabyProgressRepositoryProtocol
    private let widgetReloader: WidgetReloaderProtocol

    init(
        repository: BabyProgressRepositoryProtocol? = nil,
        widgetReloader: WidgetReloaderProtocol? = nil
    ) {
        self.repository = repository ?? DependencyContainer.shared.repository
        self.widgetReloader = widgetReloader ?? DependencyContainer.shared.widgetReloader

        let date = self.repository.getEventDate() ?? .now
        lastPeriodDate = date

        estimatedDueDate = PregnancyCalculator.calculateDueDate(lastPeriod: date)
        daysRemaining = self.repository.daysUntilEvent()
        pregnancyWeek = self.repository.getPregnancyWeek()
        currentBabySize = self.repository.getBabySize()
        babySizeString = currentBabySize?.description
        photoData = self.repository.fetchPhoto()
        photosData = self.repository.fetchAllPhotos()
    }

    func updateDate(_ date: Date) {
        lastPeriodDate = date
        estimatedDueDate = PregnancyCalculator.calculateDueDate(lastPeriod: date)
        repository.setEventDate(date)
        daysRemaining = repository.daysUntilEvent()
        pregnancyWeek = repository.getPregnancyWeek()
        currentBabySize = repository.getBabySize()
        babySizeString = currentBabySize?.description
        widgetReloader.reloadAllTimelines()
    }

    func savePhoto(_ data: Data?) {
        photoData = data
        repository.savePhoto(data: data)
    }

    func deletePhoto() {
        photoData = nil
        repository.deletePhoto()
    }

    // MARK: - Multi-photo gallery

    func addGalleryPhoto(_ data: Data) {
        repository.addPhoto(data: data)
        photosData = repository.fetchAllPhotos()
    }

    func deleteGalleryPhoto(at index: Int) {
        repository.deletePhoto(at: index)
        photosData = repository.fetchAllPhotos()
    }
}
