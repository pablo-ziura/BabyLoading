@testable import BabyLoading
import AppPreferences
import Foundation
import Testing

struct AppLanguageRepositoryTests {
    @Test func selectedLanguageUsesPersistedSupportedLanguage() throws {
        let context = try makeContext()
        defer { cleanup(context) }
        let repository = AppLanguageRepository(
            preferencesStore: context.store,
            preferredLanguages: { ["en-US"] }
        )

        repository.updateSelectedLanguage(.spanish)

        #expect(repository.selectedLanguage() == .spanish)
    }

    @Test func selectedLanguageFallsBackToSupportedSystemLanguageWhenValueIsMissing() throws {
        let context = try makeContext()
        defer { cleanup(context) }
        let repository = AppLanguageRepository(
            preferencesStore: context.store,
            preferredLanguages: { ["es-ES"] }
        )

        #expect(repository.selectedLanguage() == .spanish)
    }

    @Test func selectedLanguageIgnoresUnsupportedPersistedValue() throws {
        let context = try makeContext()
        defer { cleanup(context) }
        try context.store.write("fr", for: PreferenceKey<String>("selectedLanguage"))
        let repository = AppLanguageRepository(
            preferencesStore: context.store,
            preferredLanguages: { ["es-ES"] }
        )

        #expect(repository.selectedLanguage() == .spanish)
    }

    private func makeContext() throws -> TestContext {
        let suiteName = "AppLanguageRepositoryTests.\(UUID().uuidString)"
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
