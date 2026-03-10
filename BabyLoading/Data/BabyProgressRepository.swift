import Foundation

protocol BabyProgressRepositoryProtocol {
    func getEventDate() -> Date?
    func setEventDate(_ date: Date?)
    func daysUntilEvent() -> Int?
    func getPregnancyWeek() -> Int?
    func getCurrentWeekContent() -> WeekContent?
    func getAllWeekContent() -> [WeekContent]
    func currentContentSnapshot() -> PregnancyContentDocument
    func refreshContentIfNeeded() async
    func savePhoto(data: Data?)
    func fetchPhoto() -> Data?
    func deletePhoto()

    // Multi-photo
    func addPhoto(data: Data)
    func fetchAllPhotos() -> [Data]
    func deletePhoto(at index: Int)
}

class BabyProgressRepository: BabyProgressRepositoryProtocol {
    private let dataSource: BabyProgressDataSourceProtocol
    private let contentRepository: PregnancyContentRepositoryProtocol

    init(
        dataSource: BabyProgressDataSourceProtocol,
        contentRepository: PregnancyContentRepositoryProtocol
    ) {
        self.dataSource = dataSource
        self.contentRepository = contentRepository
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

    func savePhoto(data: Data?) {
        dataSource.savePhoto(data: data)
    }

    func fetchPhoto() -> Data? {
        return dataSource.fetchPhoto()
    }

    func deletePhoto() {
        dataSource.deletePhoto()
    }

    // MARK: - Multi-photo

    func addPhoto(data: Data) {
        dataSource.addPhoto(data: data)
    }

    func fetchAllPhotos() -> [Data] {
        return dataSource.fetchAllPhotos()
    }

    func deletePhoto(at index: Int) {
        dataSource.deletePhoto(at: index)
    }
}
