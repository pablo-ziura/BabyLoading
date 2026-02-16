import Foundation
import Observation

@Observable
class BabyProgressViewModel {
    var eventDate: Date
    var daysRemaining: Int?
    var pregnancyWeek: Int?
    var babySizeString: String?

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
    }

    func updateDate(_ date: Date) {
        eventDate = date
        repository.setEventDate(date)
        daysRemaining = repository.daysUntilEvent()
        pregnancyWeek = repository.getPregnancyWeek()
        babySizeString = repository.getBabySize()?.description
        widgetReloader.reloadAllTimelines()
    }
}
