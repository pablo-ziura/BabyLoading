import Foundation

enum SharedAppGroup {
    static let identifier = "group.com.pablo.BabyLoading"

    static func userDefaults() -> UserDefaults? {
        UserDefaults(suiteName: identifier)
    }

    static func containerURL(fileManager: FileManager = .default) -> URL? {
        fileManager.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}
