import Foundation

protocol BabyProgressDataSourceProtocol {
    func save(date: Date?)
    func fetchDate() -> Date?
}

class BabyProgressDataSource: BabyProgressDataSourceProtocol {
    private let suiteName = "group.com.pablo.BabyLoading"

    func save(date: Date?) {
        print("💾 [BabyProgressDataSource] save -> \(String(describing: date)) (suite: \(suiteName))")
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            print("⚠️ [BabyProgressDataSource] Failed to init UserDefaults with suite: \(suiteName)")
            return
        }
        defaults.set(date, forKey: "eventDate")
    }

    func fetchDate() -> Date? {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            print("⚠️ [BabyProgressDataSource] Failed to init UserDefaults with suite: \(suiteName)")
            return nil
        }
        let date = defaults.object(forKey: "eventDate") as? Date
        print("🔍 [BabyProgressDataSource] fetchDate -> \(String(describing: date)) (suite: \(suiteName))")
        return date
    }
}
