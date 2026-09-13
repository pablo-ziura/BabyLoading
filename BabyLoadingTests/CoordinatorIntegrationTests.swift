@testable import BabyLoading
import AppPreferences
import BabyLoadingInfrastructure
import CloudBackup
import DashboardFeature
import Foundation
import GalleryFeature
import JourneyFeature
import PregnancyProgress
import SettingsFeature
import Testing

@Suite(.serialized)
struct CoordinatorIntegrationTests {
    @Test @MainActor
    func startReloadsEveryFeatureViewModel() async throws {
        let fixture = try CoordinatorFixture()
        defer { fixture.removeFiles() }
        let coordinator = fixture.coordinator

        #expect(coordinator.dashboardViewModel.loadingState == .idle)
        #expect(coordinator.journeyViewModel.loadingState == .idle)
        #expect(coordinator.galleryViewModel.loadingState == .idle)
        #expect(coordinator.settingsViewModel.loadingState == .idle)

        await coordinator.start()

        #expect(coordinator.dashboardViewModel.loadingState != .idle)
        #expect(coordinator.journeyViewModel.loadingState != .idle)
        #expect(coordinator.galleryViewModel.loadingState != .idle)
        #expect(coordinator.settingsViewModel.loadingState != .idle)
    }

    @Test @MainActor
    func activationRefreshesDateDependentStateWithoutALanguageChange() async throws {
        let fixture = try CoordinatorFixture()
        defer { fixture.removeFiles() }
        let userDefaults = fixture.userDefaults

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Madrid"))
        let lastPeriodDate = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 12))
        )
        let firstActivationDate = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 1, day: 8, hour: 12))
        )
        let secondActivationDate = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 1, day: 15, hour: 12))
        )
        userDefaults.set(lastPeriodDate, forKey: "lastPeriodDate")
        let coordinator = fixture.coordinator

        await coordinator.start(asOf: firstActivationDate)
        let initialProgress = try #require(coordinator.dashboardViewModel.progress?.activeProgress)

        await coordinator.applicationDidBecomeActive(asOf: secondActivationDate)
        let refreshedProgress = try #require(coordinator.dashboardViewModel.progress?.activeProgress)

        #expect(initialProgress.gestationalAge == GestationalAge(weeks: 1, days: 0))
        #expect(refreshedProgress.gestationalAge == GestationalAge(weeks: 2, days: 0))
    }
}

private extension PregnancyProgress {
    var activeProgress: ActivePregnancyProgress? {
        guard case let .active(progress) = self else { return nil }
        return progress
    }
}

@MainActor
private final class CoordinatorFixture {
    let userDefaults: UserDefaults
    let coordinator: Coordinator
    private let suite = UUID().uuidString
    private let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

    init() throws {
        userDefaults = try #require(UserDefaults(suiteName: suite))
        coordinator = Coordinator(dependencyContainer: DependencyContainer(
            preferencesStore: try Self.preferencesStore(suite: suite),
            containerURL: root, widgetReloader: CoordinatorWidgetReloader(),
            makeBackupServices: { local, root in
                let remote = CoordinatorOfflineRemote()
                let synchronize = SynchronizeBackupUseCase(localStore: local, remoteStore: remote)
                let images = ImageUploadService(
                    localStore: local, storage: CoordinatorOfflineStorage(), preparer: CoordinatorImagePreparer(),
                    synchronize: synchronize, temporaryDirectory: root.appendingPathComponent("temporary")
                )
                return BackupServices(
                    authentication: CoordinatorOfflineAuthentication(), remoteStore: remote,
                    driver: BackupSynchronizationDriver(
                        localStore: local, remoteStore: remote, connectivity: CoordinatorOfflineConnectivity(),
                        images: images, synchronize: synchronize
                    )
                )
            }
        ))
    }
    private nonisolated static func preferencesStore(suite: String) throws -> UserDefaultsPreferencesStore {
        guard let defaults = UserDefaults(suiteName: suite) else { throw BackupFailure.unavailable }
        return UserDefaultsPreferencesStore(userDefaults: defaults)
    }

    func removeFiles() {
        userDefaults.removePersistentDomain(forName: suite)
        try? FileManager.default.removeItem(at: root)
    }
}

@MainActor
private struct CoordinatorWidgetReloader: WidgetReloaderProtocol {
    func reloadAllTimelines() {}
}

@MainActor
private final class CoordinatorOfflineAuthentication: BackupAuthenticationProtocol {
    var currentAccount: BackupAccount? { nil }
    func observeAccounts() -> AsyncStream<BackupAccount?> { AsyncStream { $0.finish() } }
    func signInAnonymously() throws { throw BackupFailure.network }
    func linkEmail(email: String, password: String) throws { throw BackupFailure.network }
    func signInEmail(email: String, password: String) throws { throw BackupFailure.network }
    func signInGoogle(linkAnonymous: Bool) throws { throw BackupFailure.network }
    func resetPassword(email: String) throws { throw BackupFailure.network }
    func sendVerification() throws { throw BackupFailure.network }
    func reauthenticate(password: String) throws { throw BackupFailure.network }
    func signOut() {}
    func deleteAccount() throws { throw BackupFailure.network }
}

private struct CoordinatorOfflineRemote: BackupRemoteStoreProtocol {
    func apply(_ mutation: BackupMutation, userID: String) throws { throw BackupFailure.network }
    func fetch(userID: String) throws -> [BackupRemoteEvent] { throw BackupFailure.network }
    func observe(userID: String) -> AsyncThrowingStream<BackupRemoteEvent, Error> {
        AsyncThrowingStream { $0.finish() }
    }
    func reset() {}
}

private struct CoordinatorOfflineStorage: BackupImageStorageProtocol {
    func upload(fileURL: URL, userID: String, logID: String) throws -> String { throw BackupFailure.network }
    func download(to fileURL: URL, userID: String, logID: String) throws { throw BackupFailure.network }
    func delete(userID: String, logID: String) throws { throw BackupFailure.network }
    func cancelAll() {}
}

private struct CoordinatorImagePreparer: BackupImagePreparingProtocol {
    func prepareJPEG(from source: URL, to destination: URL) throws { throw BackupFailure.unavailable }
    func validateDownloadedJPEG(at url: URL) throws { throw BackupFailure.unavailable }
}

private struct CoordinatorOfflineConnectivity: BackupConnectivityProtocol {
    func changes() -> AsyncStream<Bool> { AsyncStream { $0.yield(false); $0.finish() } }
}
