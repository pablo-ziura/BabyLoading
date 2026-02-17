import Foundation

protocol BabyProgressRepositoryProtocol {
    func getEventDate() -> Date?
    func setEventDate(_ date: Date?)
    func daysUntilEvent() -> Int?
    func getPregnancyWeek() -> Int?
    func getBabySize() -> BabySize?
    func savePhoto(data: Data?)
    func fetchPhoto() -> Data?
    func deletePhoto()
}

class BabyProgressRepository: BabyProgressRepositoryProtocol {
    private let dataSource: BabyProgressDataSourceProtocol

    init(dataSource: BabyProgressDataSourceProtocol) {
        self.dataSource = dataSource
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

    func getBabySize() -> BabySize? {
        guard let lastPeriodDate = getEventDate() else { return nil }
        return PregnancyCalculator.babySize(for: lastPeriodDate)
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
}
