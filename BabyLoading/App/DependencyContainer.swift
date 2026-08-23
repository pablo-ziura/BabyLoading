import AppLocalization
import AppPreferences
import BabyLoadingInfrastructure
import Foundation
import PregnancyContent
import PregnancyProgress

@MainActor
final class DependencyContainer {
    let dataSource: BabyProgressDataSourceProtocol
    let repository: BabyProgressRepositoryProtocol
    let widgetReloader: WidgetReloaderProtocol
    let resolveAppLanguageUseCase: any ResolveAppLanguageUseCaseProtocol
    let loadAppVersionUseCase: any LoadAppVersionUseCaseProtocol
    let loadPregnancyProgressUseCase: any LoadPregnancyProgressUseCaseProtocol
    let updateLastPeriodDateUseCase: any UpdateLastPeriodDateUseCaseProtocol
    let initialLanguage: AppLanguage

    private let contentBundle: Bundle
    private let sharedContainerURL: URL

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

        let resolveAppLanguageUseCase = ResolveAppLanguageUseCase()
        let initialLanguage = resolveAppLanguageUseCase.execute(
            preferredLanguages: Bundle.main.preferredLocalizations + Locale.preferredLanguages
        )

        let pregnancyProgressStore = PregnancyProgressStore(preferencesStore: preferencesStore)
        let pregnancyProgressRepository = PregnancyProgressRepository(store: pregnancyProgressStore)

        dataSource = BabyProgressDataSource(fileManager: fileManager, containerURL: containerURL)
        repository = BabyProgressRepository(dataSource: dataSource)
        widgetReloader = DefaultWidgetReloader()
        self.resolveAppLanguageUseCase = resolveAppLanguageUseCase
        loadAppVersionUseCase = LoadAppVersionUseCase(
            provider: BundleAppVersionProvider(bundle: .main)
        )
        loadPregnancyProgressUseCase = LoadPregnancyProgressUseCase(
            repository: pregnancyProgressRepository,
            calendar: .current
        )
        updateLastPeriodDateUseCase = UpdateLastPeriodDateUseCase(
            repository: pregnancyProgressRepository
        )
        self.initialLanguage = initialLanguage
        contentBundle = .main
        sharedContainerURL = containerURL
    }

    func makePregnancyContentUseCases(
        for language: AppLanguage
    ) -> (
        loadWeekContent: any LoadPregnancyWeekContentUseCaseProtocol,
        loadTimeline: any LoadPregnancyTimelineUseCaseProtocol
    ) {
        let localization = PregnancyContentLocalization(localeCode: language.rawValue)
        let repository = PregnancyContentRepository(
            expectedLocale: localization.localeCode,
            bundleSource: BundlePregnancyContentSource(
                bundle: contentBundle,
                localization: localization
            ),
            legacyCacheSource: LegacyPregnancyContentCacheStore(
                localization: localization,
                containerURL: sharedContainerURL
            )
        )

        return (
            loadWeekContent: LoadPregnancyWeekContentUseCase(repository: repository),
            loadTimeline: LoadPregnancyTimelineUseCase(repository: repository)
        )
    }
}
