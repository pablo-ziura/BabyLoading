import AppPreferences
import Foundation
import Testing

struct UserDefaultsPreferencesStoreTests {
    private struct PreferenceValue: Codable, Equatable, Sendable {
        let value: String
    }

    @Test func writeAndReadRoundTrip() async throws {
        let context = try makeContext()
        defer { cleanup(context) }
        let key = PreferenceKey<String>("selectedLanguage")

        try await context.store.write("es", for: key)

        #expect(try await context.store.read(key) == "es")
    }

    @Test func removeDeletesStoredValue() async throws {
        let context = try makeContext()
        defer { cleanup(context) }
        let key = PreferenceKey<String>("selectedLanguage")
        try await context.store.write("en", for: key)

        await context.store.remove(key)

        #expect(try await context.store.read(key) == nil)
    }

    @Test func readThrowsForInvalidEncodedData() async throws {
        let context = try makeContext()
        defer { cleanup(context) }
        let key = PreferenceKey<PreferenceValue>("invalid")
        context.userDefaults.set(Data("not-json".utf8), forKey: key.name)

        await #expect(throws: PreferencesError.self) {
            try await context.store.read(key)
        }
    }

    @Test func readSupportsLegacyNativeDate() async throws {
        let context = try makeContext()
        defer { cleanup(context) }
        let key = PreferenceKey<Date>("lastPeriodDate")
        let expectedDate = Date(timeIntervalSince1970: 1_234_567)
        context.userDefaults.set(expectedDate, forKey: key.name)

        #expect(try await context.store.read(key) == expectedDate)
    }

    private func makeContext() throws -> TestContext {
        let suiteName = "AppPreferencesTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        let storeUserDefaults = try #require(UserDefaults(suiteName: suiteName))
        userDefaults.removePersistentDomain(forName: suiteName)
        return TestContext(
            suiteName: suiteName,
            userDefaults: userDefaults,
            store: UserDefaultsPreferencesStore(userDefaults: storeUserDefaults)
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
