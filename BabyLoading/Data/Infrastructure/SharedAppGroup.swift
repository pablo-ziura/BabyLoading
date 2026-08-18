import AppPreferences
import Foundation

enum SharedAppGroup {
    static let identifier = "group.com.pablo.BabyLoading"

    static func userDefaults() -> UserDefaults? {
        UserDefaults(suiteName: identifier)
    }

    static func preferencesStore() -> UserDefaultsPreferencesStore? {
        guard let userDefaults = userDefaults() else {
            return nil
        }

        return UserDefaultsPreferencesStore(userDefaults: userDefaults)
    }

    static func containerURL(fileManager: FileManager = .default) -> URL? {
        fileManager.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}
