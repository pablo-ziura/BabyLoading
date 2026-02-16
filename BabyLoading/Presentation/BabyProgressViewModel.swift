import Foundation
import Observation
import WidgetKit

@Observable
class BabyProgressViewModel {
    var eventDate: Date
    var daysRemaining: Int?
    
    // Private Repository dependency
    private let repository: BabyProgressRepositoryProtocol
    
    init(repository: BabyProgressRepositoryProtocol = DependencyContainer.shared.repository) {
        self.repository = repository
        // Initialize with stored date or current date if none exists
        self.eventDate = repository.getEventDate() ?? Date()
        self.daysRemaining = repository.daysUntilEvent()
    }
    
    func updateDate(_ date: Date) {
        self.eventDate = date
        repository.setEventDate(date)
        self.daysRemaining = repository.daysUntilEvent()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
