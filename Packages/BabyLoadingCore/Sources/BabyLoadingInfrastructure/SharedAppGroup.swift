import Foundation

public enum SharedAppGroupError: Error, Equatable, Sendable {
    case unavailableUserDefaults(identifier: String)
    case unavailableContainer(identifier: String)
}

public enum SharedAppGroup {
    public static let identifier = "group.com.pablo.BabyLoading"

    public static func userDefaults() throws -> UserDefaults {
        guard let userDefaults = UserDefaults(suiteName: identifier) else {
            throw SharedAppGroupError.unavailableUserDefaults(identifier: identifier)
        }

        return userDefaults
    }

    public static func containerURL(fileManager: FileManager) throws -> URL {
        guard let containerURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: identifier
        ) else {
            throw SharedAppGroupError.unavailableContainer(identifier: identifier)
        }

        return containerURL
    }
}
