import AppLocalization
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
    var ultrasoundPhotos: [UltrasoundPhoto] = []
    var bellyTrackingEntries: [BellyTrackingEntry] = []
    var bellyTrackingSettings: BellyTrackingSettings
    var showingPhotoPicker = false
    private(set) var appLanguage: AppLanguage
    let appVersion: String

    private let repository: BabyProgressRepositoryProtocol
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
        repository: BabyProgressRepositoryProtocol,
        initialLanguage: AppLanguage,
        appVersion: String,
        widgetReloader: WidgetReloaderProtocol
    ) {
        self.repository = repository
        self.widgetReloader = widgetReloader
        appLanguage = initialLanguage
        self.appVersion = appVersion

        lastPeriodDate = self.repository.getEventDate() ?? .now
        allWeekContent = self.repository.getAllWeekContent()
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

    @discardableResult
    func applyContentLanguage(_ language: AppLanguage) -> Bool {
        guard language != appLanguage else {
            return false
        }

        appLanguage = language
        repository.updateContentLanguage(language)
        reloadProgressState()
        return true
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
