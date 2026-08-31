@testable import BabyLoading
import BabyLoadingInfrastructure
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
    func startReloadsEveryFeatureViewModel() async {
        let coordinator = Coordinator()

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
        let userDefaults = try SharedAppGroup(bundle: .main).userDefaults()
        let originalValue = userDefaults.object(forKey: "lastPeriodDate")
        defer {
            if let originalValue {
                userDefaults.set(originalValue, forKey: "lastPeriodDate")
            } else {
                userDefaults.removeObject(forKey: "lastPeriodDate")
            }
        }

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
        let coordinator = Coordinator()

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
