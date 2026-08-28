import AppLocalization
import AppPreferences
import BabyLoadingInfrastructure
import BabyProgressWidgetSupport
import Foundation
import PregnancyContent
import PregnancyProgress

@MainActor
final class WidgetDependencyContainer {
    let language: AppLanguage
    let timelineProvider: BabyProgressTimelineProvider

    init() {
        let fileManager = FileManager.default
        let sharedAppGroup: SharedAppGroup
        let preferencesStore: UserDefaultsPreferencesStore
        let containerURL: URL

        do {
            sharedAppGroup = try SharedAppGroup(bundle: .main)
            preferencesStore = UserDefaultsPreferencesStore(
                userDefaults: try sharedAppGroup.userDefaults()
            )
            containerURL = try sharedAppGroup.containerURL(fileManager: fileManager)
        } catch {
            preconditionFailure("BabyLoading App Group is unavailable: \(error)")
        }

        let language = ResolveAppLanguageUseCase().execute(
            preferredLanguages: Bundle.main.preferredLocalizations + Locale.preferredLanguages
        )
        let progressStore = PregnancyProgressStore(preferencesStore: preferencesStore)
        let progressRepository = PregnancyProgressRepository(store: progressStore)
        let loadPregnancyProgressUseCase = LoadPregnancyProgressUseCase(
            repository: progressRepository,
            calendar: .current
        )
        let contentLocalization = PregnancyContentLocalization(localeCode: language.rawValue)
        let contentRepository = PregnancyContentRepository(
            expectedLocale: contentLocalization.localeCode,
            bundleSource: BundlePregnancyContentSource(
                bundle: .main,
                localization: contentLocalization
            ),
            legacyCacheSource: LegacyPregnancyContentCacheStore(
                localization: contentLocalization,
                containerURL: containerURL
            )
        )

        let loadSnapshotUseCase = LoadBabyProgressWidgetSnapshotUseCase(
            loadPregnancyProgressUseCase: loadPregnancyProgressUseCase,
            loadPregnancyWeekContentUseCase: LoadPregnancyWeekContentUseCase(
                repository: contentRepository
            ),
            language: language
        )

        self.language = language
        timelineProvider = BabyProgressTimelineProvider(
            loadSnapshotUseCase: loadSnapshotUseCase,
            loadTimelineUseCase: LoadBabyProgressWidgetTimelineUseCase(
                loadSnapshotUseCase: loadSnapshotUseCase,
                calendar: .current
            ),
            language: language
        )
    }
}
