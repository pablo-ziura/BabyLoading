import Foundation
import Observation

@Observable
@MainActor
class BabyProgressViewModel {
    var lastPeriodDate: Date
    var estimatedDueDate: Date?
    var daysRemaining: Int?
    var pregnancyWeek: Int?
    var currentWeekContent: WeekContent?
    var allWeekContent: [WeekContent]
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

        lastPeriodDate = self.repository.getEventDate() ?? .now
        allWeekContent = self.repository.getAllWeekContent()
        photoData = self.repository.fetchPhoto()
        photosData = self.repository.fetchAllPhotos()
        estimatedDueDate = nil
        daysRemaining = nil
        pregnancyWeek = nil
        currentWeekContent = nil

        reloadProgressState()
    }

    func updateDate(_ date: Date) {
        lastPeriodDate = date
        repository.setEventDate(date)
        reloadProgressState()
        widgetReloader.reloadAllTimelines()
    }

    func refreshContentIfNeeded() async {
        let previousSnapshot = repository.currentContentSnapshot()
        await repository.refreshContentIfNeeded()
        reloadProgressState()

        if repository.currentContentSnapshot() != previousSnapshot {
            widgetReloader.reloadAllTimelines()
        }
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

    private func reloadProgressState() {
        let savedDate = repository.getEventDate()
        estimatedDueDate = savedDate.map(PregnancyCalculator.calculateDueDate)
        daysRemaining = repository.daysUntilEvent()
        pregnancyWeek = repository.getPregnancyWeek()
        currentWeekContent = repository.getCurrentWeekContent()
        allWeekContent = repository.getAllWeekContent()
    }
}
