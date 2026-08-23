import Foundation

class BabyProgressRepository: BabyProgressRepositoryProtocol {
    private let dataSource: BabyProgressDataSourceProtocol
    private let contentRepositoryFactory: PregnancyContentRepositoryFactoryProtocol?
    private var contentRepository: PregnancyContentRepositoryProtocol

    init(
        dataSource: BabyProgressDataSourceProtocol,
        contentRepository: PregnancyContentRepositoryProtocol
    ) {
        self.dataSource = dataSource
        self.contentRepository = contentRepository
        contentRepositoryFactory = nil
    }

    init(
        dataSource: BabyProgressDataSourceProtocol,
        contentRepositoryFactory: PregnancyContentRepositoryFactoryProtocol,
        initialLanguage: AppLanguage
    ) {
        self.dataSource = dataSource
        self.contentRepositoryFactory = contentRepositoryFactory
        contentRepository = contentRepositoryFactory.makeRepository(for: initialLanguage)
    }

    func getEventDate() -> Date? {
        return dataSource.fetchDate()
    }

    func setEventDate(_ date: Date?) {
        dataSource.save(date: date)
    }

    func daysUntilEvent() -> Int? {
        guard let lastPeriodDate = getEventDate() else { return nil }
        let dueDate = PregnancyCalculator.calculateDueDate(lastPeriod: lastPeriodDate)

        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        let startOfDueDate = calendar.startOfDay(for: dueDate)

        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfDueDate)
        return max(0, components.day ?? 0)
    }

    func getPregnancyWeek() -> Int? {
        guard let lastPeriodDate = getEventDate() else { return nil }
        return PregnancyCalculator.currentWeek(lastPeriod: lastPeriodDate)
    }

    func getCurrentWeekContent() -> WeekContent? {
        guard let week = getPregnancyWeek() else { return nil }
        return contentRepository.weekContent(for: week)
    }

    func getAllWeekContent() -> [WeekContent] {
        contentRepository.allWeekContent()
    }

    func currentContentSnapshot() -> PregnancyContentDocument {
        contentRepository.currentSnapshot()
    }

    func refreshContentIfNeeded() async {
        await contentRepository.refreshIfNeeded()
    }

    func updateContentLanguage(_ language: AppLanguage) {
        guard let contentRepositoryFactory else {
            return
        }

        contentRepository = contentRepositoryFactory.makeRepository(for: language)
    }

    func savePhoto(data: Data?) {
        dataSource.savePhoto(data: data)
    }

    func fetchPhoto() -> Data? {
        return dataSource.fetchPhoto()
    }

    func deletePhoto() {
        dataSource.deletePhoto()
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
