import Foundation

public enum PreferencesError: Error, Equatable, Sendable {
    case encoding(key: String, description: String)
    case decoding(key: String, description: String)
}
