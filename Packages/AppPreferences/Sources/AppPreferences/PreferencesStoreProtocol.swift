import Foundation

public protocol PreferencesStoreProtocol: Sendable {
    func read<Value: Codable & Sendable>(_ key: PreferenceKey<Value>) throws -> Value?
    func write<Value: Codable & Sendable>(_ value: Value, for key: PreferenceKey<Value>) throws
    func remove<Value: Codable & Sendable>(_ key: PreferenceKey<Value>)
}
