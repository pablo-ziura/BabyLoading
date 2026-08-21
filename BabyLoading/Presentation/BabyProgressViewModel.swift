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
    var ultrasoundPhotos: [UltrasoundPhoto] = []
    var bellyTrackingEntries: [BellyTrackingEntry] = []
    var bellyTrackingSettings: BellyTrackingSettings
    var showingPhotoPicker = false
    private(set) var appLanguage: AppLanguage
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

    func bellyTrackingStatus(asOf date: Date) -> BellyTrackingStatus {
        bellyTrackingSettings.trackingStatus(
            lastCapture: lastBellyTrackingEntry?.capturedAt,
            asOf: date
        )
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
        appLanguage = self.languageRepository.resolvedLanguage()
        appVersion = (appVersionProvider ?? DependencyContainer.shared.appVersionProvider).marketingVersion()

        lastPeriodDate = self.repository.getEventDate() ?? .now
        allWeekContent = self.repository.getAllWeekContent()
        photoData = self.repository.fetchPhoto()
        ultrasoundPhotos = self.repository.fetchUltrasoundPhotos()
        bellyTrackingSettings = self.repository.fetchBellyTrackingSettings()
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

    func refreshContentIfNeeded() async {
        let languageDidChange = reloadLanguageFromSystemIfNeeded()
        let previousSnapshot = repository.currentContentSnapshot()
        await repository.refreshContentIfNeeded()
        reloadProgressState()

        if languageDidChange || repository.currentContentSnapshot() != previousSnapshot {
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

    // MARK: - Ultrasound gallery

    func addUltrasoundPhoto(_ data: Data) {
        repository.addUltrasoundPhoto(data: data)
        ultrasoundPhotos = repository.fetchUltrasoundPhotos()
    }

    func deleteUltrasoundPhoto(id: String) {
        repository.deleteUltrasoundPhoto(id: id)
        ultrasoundPhotos = repository.fetchUltrasoundPhotos()
    }

    func saveBellyTrackingPhoto(_ data: Data) -> Bool {
        let savedEntry = repository.saveBellyTrackingPhoto(
            data: data,
            capturedAt: .now,
            pregnancyWeekAtCapture: pregnancyWeek
        )

        reloadBellyTrackingState()
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

    private func reloadLanguageFromSystemIfNeeded() -> Bool {
        let systemLanguage = languageRepository.resolvedLanguage()
        guard systemLanguage != appLanguage else {
            return false
        }

        appLanguage = systemLanguage
        repository.updateContentLanguage(systemLanguage)
        reloadProgressState()
        return true
    }

    private func reloadBellyTrackingState() {
        bellyTrackingEntries = repository.fetchBellyTrackingEntries()
        bellyTrackingSettings = repository.fetchBellyTrackingSettings()
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
