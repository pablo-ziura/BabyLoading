import Foundation

public enum SharedAppGroupError: Error, Equatable, Sendable {
    case missingConfigurationValue(key: String)
    case invalidIdentifier(String)
    case unavailableUserDefaults(identifier: String)
    case unavailableContainer(identifier: String)
}

public struct SharedAppGroup: Sendable {
    public static let productionIdentifier = "group.com.pablo.BabyLoading"
    public static let infoPlistKey = "BabyLoadingAppGroupIdentifier"

    public let identifier: String

    public init(identifier: String) throws {
        guard !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SharedAppGroupError.invalidIdentifier(identifier)
        }

        self.identifier = identifier
    }

    public init(bundle: Bundle) throws {
        guard let identifier = bundle.object(
            forInfoDictionaryKey: Self.infoPlistKey
        ) as? String else {
            throw SharedAppGroupError.missingConfigurationValue(key: Self.infoPlistKey)
        }

        try self.init(identifier: identifier)
    }

    public func userDefaults() throws -> UserDefaults {
        guard let userDefaults = UserDefaults(suiteName: identifier) else {
            throw SharedAppGroupError.unavailableUserDefaults(identifier: identifier)
        }

        return userDefaults
    }

    public func containerURL(fileManager: FileManager) throws -> URL {
        guard let containerURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: identifier
        ) else {
            throw SharedAppGroupError.unavailableContainer(identifier: identifier)
        }

        return containerURL
    }
}
