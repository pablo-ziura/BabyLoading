import Foundation

protocol BabyProgressDataSourceProtocol {
    func save(date: Date?)
    func fetchDate() -> Date?
}

class BabyProgressDataSource: BabyProgressDataSourceProtocol {
    private let suiteName = "group.com.pablo.BabyLoading"

    func save(date: Date?) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.set(date, forKey: "eventDate")
    }

    func fetchDate() -> Date? {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return nil }
        return defaults.object(forKey: "eventDate") as? Date
    }
}
