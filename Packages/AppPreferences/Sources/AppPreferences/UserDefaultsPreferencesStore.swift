import Foundation

public actor UserDefaultsPreferencesStore: PreferencesStoreProtocol {
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(userDefaults: sending UserDefaults) {
        self.userDefaults = userDefaults
        encoder = JSONEncoder()
        decoder = JSONDecoder()
    }

    public func read<Value: Codable & Sendable>(_ key: PreferenceKey<Value>) throws -> Value? {
        guard let storedValue = userDefaults.object(forKey: key.name) else {
            return nil
        }

        if let nativeValue = storedValue as? Value {
            return nativeValue
        }

        guard let data = storedValue as? Data else {
            return nil
        }

        do {
            return try decoder.decode(Value.self, from: data)
        } catch {
            throw PreferencesError.decoding(key: key.name, description: String(describing: error))
        }
    }

    public func write<Value: Codable & Sendable>(_ value: Value, for key: PreferenceKey<Value>) throws {
        do {
            userDefaults.set(try encoder.encode(value), forKey: key.name)
        } catch {
            throw PreferencesError.encoding(key: key.name, description: String(describing: error))
        }
    }

    public func remove<Value: Codable & Sendable>(_ key: PreferenceKey<Value>) {
        userDefaults.removeObject(forKey: key.name)
    }
}
