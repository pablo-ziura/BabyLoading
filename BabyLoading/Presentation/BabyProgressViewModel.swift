import Foundation
import Observation

@Observable
class BabyProgressViewModel {
    var eventDate: Date
    var daysRemaining: Int?
    var pregnancyWeek: Int?
    var babySizeString: String?
    var photoData: Data?
    var showingPhotoPicker = false

    private let repository: BabyProgressRepositoryProtocol
    private let widgetReloader: WidgetReloaderProtocol

    init(repository: BabyProgressRepositoryProtocol? = nil,
         widgetReloader: WidgetReloaderProtocol? = nil) {
        self.repository = repository ?? DependencyContainer.shared.repository
        self.widgetReloader = widgetReloader ?? DependencyContainer.shared.widgetReloader

        eventDate = self.repository.getEventDate() ?? .now
        daysRemaining = self.repository.daysUntilEvent()
        pregnancyWeek = self.repository.getPregnancyWeek()
        babySizeString = self.repository.getBabySize()?.description
        photoData = self.repository.fetchPhoto()
    }

    func updateDate(_ date: Date) {
        eventDate = date
        repository.setEventDate(date)
        daysRemaining = repository.daysUntilEvent()
        pregnancyWeek = repository.getPregnancyWeek()
        babySizeString = repository.getBabySize()?.description
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
}
