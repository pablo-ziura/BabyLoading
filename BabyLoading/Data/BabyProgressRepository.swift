import Foundation

protocol BabyProgressRepositoryProtocol {
    func getEventDate() -> Date?
    func setEventDate(_ date: Date?)
    func daysUntilEvent() -> Int?
    func getPregnancyWeek() -> Int?
    func getBabySize() -> BabySize?
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
        guard let date = getEventDate() else { return nil }
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        let startOfEventDate = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfEventDate)
        return max(0, components.day ?? 0)
    }

    func getPregnancyWeek() -> Int? {
        guard let date = getEventDate() else { return nil }
        return PregnancyCalculator.currentWeek(dueDate: date)
    }

    func getBabySize() -> BabySize? {
        guard let date = getEventDate() else { return nil }
        return PregnancyCalculator.babySize(for: date)
    }
}
