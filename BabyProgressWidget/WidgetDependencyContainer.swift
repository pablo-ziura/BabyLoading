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
        let preferencesStore: UserDefaultsPreferencesStore
        let containerURL: URL

        do {
            preferencesStore = UserDefaultsPreferencesStore(
                userDefaults: try SharedAppGroup.userDefaults()
            )
            containerURL = try SharedAppGroup.containerURL(fileManager: fileManager)
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

        self.language = language
        timelineProvider = BabyProgressTimelineProvider(
            loadSnapshotUseCase: LoadBabyProgressWidgetSnapshotUseCase(
                loadPregnancyProgressUseCase: loadPregnancyProgressUseCase,
                loadPregnancyWeekContentUseCase: LoadPregnancyWeekContentUseCase(
                    repository: contentRepository
                ),
                language: language
            ),
            language: language
        )
    }
}
