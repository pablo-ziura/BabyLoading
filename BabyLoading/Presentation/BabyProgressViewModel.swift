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
    var bellyTrackingEntries: [BellyTrackingEntry] = []
    var bellyTrackingSettings: BellyTrackingSettings
    var nextBellyTrackingDueDate: Date?
    var showingPhotoPicker = false
    var selectedLanguage: AppLanguage
    let availableLanguages: [AppLanguage]
    let appVersion: String

    private let repository: BabyProgressRepositoryProtocol
    private let languageRepository: AppLanguageRepositoryProtocol
    private let widgetReloader: WidgetReloaderProtocol
    private var bellyTrackingImageDataByEntryID: [UUID: Data] = [:]

    var lastBellyTrackingEntry: BellyTrackingEntry? {
        bellyTrackingEntries.last
    }

    var lastBellyTrackingImageData: Data? {
        guard let lastBellyTrackingEntry else { return nil }
        return bellyTrackingImageDataByEntryID[lastBellyTrackingEntry.id]
    }

    var isBellyTrackingDue: Bool {
        guard let nextBellyTrackingDueDate else { return false }
        let calendar = Calendar.current
        return calendar.startOfDay(for: .now) >= calendar.startOfDay(for: nextBellyTrackingDueDate)
    }

    init(
        repository: BabyProgressRepositoryProtocol? = nil,
        languageRepository: AppLanguageRepositoryProtocol? = nil,
        appVersionProvider: AppVersionProviding? = nil,
        widgetReloader: WidgetReloaderProtocol? = nil
    ) {
        self.repository = repository ?? DependencyContainer.shared.repository
        self.languageRepository = languageRepository ?? DependencyContainer.shared.languageRepository
        self.widgetReloader = widgetReloader ?? DependencyContainer.shared.widgetReloader
        selectedLanguage = self.languageRepository.selectedLanguage()
        availableLanguages = self.languageRepository.availableLanguages
        appVersion = (appVersionProvider ?? DependencyContainer.shared.appVersionProvider).marketingVersion()

        lastPeriodDate = self.repository.getEventDate() ?? .now
        allWeekContent = self.repository.getAllWeekContent()
        photoData = self.repository.fetchPhoto()
        photosData = self.repository.fetchAllPhotos()
        bellyTrackingSettings = self.repository.fetchBellyTrackingSettings()
        nextBellyTrackingDueDate = self.repository.nextBellyTrackingDueDate()
        estimatedDueDate = nil
        daysRemaining = nil
        pregnancyWeek = nil
        currentWeekContent = nil

        reloadProgressState()
        reloadBellyTrackingState()
    }

    func updateDate(_ date: Date) {
        lastPeriodDate = date
        repository.setEventDate(date)
        reloadProgressState()
        widgetReloader.reloadAllTimelines()
    }

    func updateLanguage(_ language: AppLanguage) {
        guard language != selectedLanguage else {
            return
        }

        languageRepository.updateSelectedLanguage(language)
        selectedLanguage = language
        repository.updateContentLanguage(language)
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

    func saveBellyTrackingPhoto(_ data: Data) -> Bool {
        let savedEntry = repository.saveBellyTrackingPhoto(
            data: data,
            capturedAt: .now,
            pregnancyWeekAtCapture: pregnancyWeek
        )

        reloadBellyTrackingState()
        photosData = repository.fetchAllPhotos()
        return savedEntry != nil
    }

    func deleteBellyTrackingEntry(id: UUID) {
        repository.deleteBellyTrackingEntry(id: id)
        reloadBellyTrackingState()
    }

    func updateBellyTrackingCadence(intervalDays: Int) {
        let settings = BellyTrackingSettings(intervalDays: intervalDays)
        repository.saveBellyTrackingSettings(settings)
        reloadBellyTrackingState()
    }

    func bellyTrackingImageData(for entry: BellyTrackingEntry) -> Data? {
        bellyTrackingImageDataByEntryID[entry.id]
    }

    private func reloadProgressState() {
        let savedDate = repository.getEventDate()
        estimatedDueDate = savedDate.map(PregnancyCalculator.calculateDueDate)
        daysRemaining = repository.daysUntilEvent()
        pregnancyWeek = repository.getPregnancyWeek()
        currentWeekContent = repository.getCurrentWeekContent()
        allWeekContent = repository.getAllWeekContent()
    }

    private func reloadBellyTrackingState() {
        bellyTrackingEntries = repository.fetchBellyTrackingEntries()
        bellyTrackingSettings = repository.fetchBellyTrackingSettings()
        nextBellyTrackingDueDate = repository.nextBellyTrackingDueDate()
        bellyTrackingImageDataByEntryID = Dictionary(
            uniqueKeysWithValues: bellyTrackingEntries.compactMap { entry in
                guard let data = repository.fetchBellyTrackingImageData(for: entry.imageFileName) else {
                    return nil
                }

                return (entry.id, data)
            }
        )
    }
}
