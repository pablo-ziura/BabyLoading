@testable import BabyLoading
import AppPreferences
import Foundation
import Testing

struct BabyProgressDataSourcePreferencesTests {
    @Test func datePersistsThroughInjectedPreferencesStore() throws {
        let context = try makeContext()
        defer { cleanup(context) }
        let date = Date(timeIntervalSince1970: 2_024_040_1)
        let dataSource = makeDataSource(context)

        dataSource.save(date: date)

        let reloadedDataSource = makeDataSource(context)
        #expect(reloadedDataSource.fetchDate() == date)
    }

    @Test func dateReadsLegacyNativeUserDefaultsValue() throws {
        let context = try makeContext()
        defer { cleanup(context) }
        let date = Date(timeIntervalSince1970: 2_024_040_2)
        context.userDefaults.set(date, forKey: "lastPeriodDate")

        #expect(makeDataSource(context).fetchDate() == date)
    }

    private func makeContext() throws -> TestContext {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)

        let suiteName = "BabyProgressDataSourcePreferencesTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        userDefaults.removePersistentDomain(forName: suiteName)
        return TestContext(
            suiteName: suiteName,
            userDefaults: userDefaults,
            preferencesStore: UserDefaultsPreferencesStore(userDefaults: userDefaults),
            containerURL: temporaryDirectory
        )
    }

    private func makeDataSource(_ context: TestContext) -> BabyProgressDataSource {
        BabyProgressDataSource(
            preferencesStore: context.preferencesStore,
            fileManager: .default,
            containerURL: context.containerURL
        )
    }

    private func cleanup(_ context: TestContext) {
        context.userDefaults.removePersistentDomain(forName: context.suiteName)
        try? FileManager.default.removeItem(at: context.containerURL)
    }
}

private struct TestContext {
    let suiteName: String
    let userDefaults: UserDefaults
    let preferencesStore: UserDefaultsPreferencesStore
    let containerURL: URL
}
