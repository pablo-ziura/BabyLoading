@testable import BabyLoading
import AppPreferences
import BabyLoadingInfrastructure
import Foundation
import Testing

struct SharedPersistenceContractTests {
    @Test func appGroupIdentifierRemainsCompatibleAcrossTargets() {
        #expect(SharedAppGroup.identifier == "group.com.pablo.BabyLoading")
    }

    @Test func lastPeriodDateUsesTheExistingPreferenceKeyAndRemovalSemantics() throws {
        let context = try makeContext()
        defer { cleanup(context) }
        let date = Date(timeIntervalSince1970: 1_772_361_000)
        let dataSource = BabyProgressDataSource(
            preferencesStore: context.preferencesStore,
            fileManager: .default,
            containerURL: context.containerURL
        )

        dataSource.save(date: date)

        #expect(context.userDefaults.object(forKey: "lastPeriodDate") is Data)
        #expect(dataSource.fetchDate() == date)

        dataSource.save(date: nil)

        #expect(context.userDefaults.object(forKey: "lastPeriodDate") == nil)
        #expect(dataSource.fetchDate() == nil)
    }

    private func makeContext() throws -> SharedPersistenceTestContext {
        let containerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true)

        let suiteName = "SharedPersistenceContractTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        userDefaults.removePersistentDomain(forName: suiteName)

        return SharedPersistenceTestContext(
            suiteName: suiteName,
            userDefaults: userDefaults,
            preferencesStore: UserDefaultsPreferencesStore(userDefaults: userDefaults),
            containerURL: containerURL
        )
    }

    private func cleanup(_ context: SharedPersistenceTestContext) {
        context.userDefaults.removePersistentDomain(forName: context.suiteName)

        do {
            try FileManager.default.removeItem(at: context.containerURL)
        } catch {
            Issue.record("Failed to remove test container: \(error)")
        }
    }
}

private struct SharedPersistenceTestContext {
    let suiteName: String
    let userDefaults: UserDefaults
    let preferencesStore: UserDefaultsPreferencesStore
    let containerURL: URL
}
