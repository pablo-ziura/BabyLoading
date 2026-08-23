import Foundation

public protocol PreferencesStoreProtocol: Sendable {
    func read<Value: Codable & Sendable>(_ key: PreferenceKey<Value>) async throws -> Value?
    func write<Value: Codable & Sendable>(_ value: Value, for key: PreferenceKey<Value>) async throws
    func remove<Value: Codable & Sendable>(_ key: PreferenceKey<Value>) async
}
