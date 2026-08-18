import AppPreferences
import Foundation
import Testing

struct UserDefaultsPreferencesStoreTests {
    private struct PreferenceValue: Codable, Equatable, Sendable {
        let value: String
    }

    @Test func writeAndReadRoundTrip() throws {
        let context = try makeContext()
        defer { cleanup(context) }
        let key = PreferenceKey<String>("selectedLanguage")

        try context.store.write("es", for: key)

        #expect(try context.store.read(key) == "es")
    }

    @Test func removeDeletesStoredValue() throws {
        let context = try makeContext()
        defer { cleanup(context) }
        let key = PreferenceKey<String>("selectedLanguage")
        try context.store.write("en", for: key)

        context.store.remove(key)

        #expect(try context.store.read(key) == nil)
    }

    @Test func readThrowsForInvalidEncodedData() throws {
        let context = try makeContext()
        defer { cleanup(context) }
        let key = PreferenceKey<PreferenceValue>("invalid")
        context.userDefaults.set(Data("not-json".utf8), forKey: key.name)

        #expect(throws: PreferencesError.self) {
            try context.store.read(key)
        }
    }

    @Test func readSupportsLegacyNativeDate() throws {
        let context = try makeContext()
        defer { cleanup(context) }
        let key = PreferenceKey<Date>("lastPeriodDate")
        let expectedDate = Date(timeIntervalSince1970: 1_234_567)
        context.userDefaults.set(expectedDate, forKey: key.name)

        #expect(try context.store.read(key) == expectedDate)
    }

    private func makeContext() throws -> TestContext {
        let suiteName = "AppPreferencesTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        userDefaults.removePersistentDomain(forName: suiteName)
        return TestContext(
            suiteName: suiteName,
            userDefaults: userDefaults,
            store: UserDefaultsPreferencesStore(userDefaults: userDefaults)
        )
    }

    private func cleanup(_ context: TestContext) {
        context.userDefaults.removePersistentDomain(forName: context.suiteName)
    }
}

private struct TestContext {
    let suiteName: String
    let userDefaults: UserDefaults
    let store: UserDefaultsPreferencesStore
}
