import AppLocalization
import AppPreferences
import BabyLoadingInfrastructure
import BellyTracking
import Foundation
import PregnancyContent
import PregnancyProgress
import UltrasoundGallery

@MainActor
final class DependencyContainer {
    let widgetReloader: WidgetReloaderProtocol
    let resolveAppLanguageUseCase: any ResolveAppLanguageUseCaseProtocol
    let loadAppVersionUseCase: any LoadAppVersionUseCaseProtocol
    let loadPregnancyProgressUseCase: any LoadPregnancyProgressUseCaseProtocol
    let updateLastPeriodDateUseCase: any UpdateLastPeriodDateUseCaseProtocol
    let loadUltrasoundPhotosUseCase: any LoadUltrasoundPhotosUseCaseProtocol
    let addUltrasoundPhotoUseCase: any AddUltrasoundPhotoUseCaseProtocol
    let deleteUltrasoundPhotoUseCase: any DeleteUltrasoundPhotoUseCaseProtocol
    let loadBellyTrackingTimelineUseCase: any LoadBellyTrackingTimelineUseCaseProtocol
    let loadBellyTrackingImageUseCase: any LoadBellyTrackingImageUseCaseProtocol
    let captureBellyTrackingPhotoUseCase: any CaptureBellyTrackingPhotoUseCaseProtocol
    let deleteBellyTrackingEntryUseCase: any DeleteBellyTrackingEntryUseCaseProtocol
    let loadBellyTrackingSettingsUseCase: any LoadBellyTrackingSettingsUseCaseProtocol
    let updateBellyTrackingSettingsUseCase: any UpdateBellyTrackingSettingsUseCaseProtocol
    let resolveBellyTrackingStatusUseCase: any ResolveBellyTrackingStatusUseCaseProtocol
    let initialLanguage: AppLanguage

    private let contentBundle: Bundle
    private let sharedContainerURL: URL

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

        let resolveAppLanguageUseCase = ResolveAppLanguageUseCase()
        let initialLanguage = resolveAppLanguageUseCase.execute(
            preferredLanguages: Bundle.main.preferredLocalizations + Locale.preferredLanguages
        )

        let pregnancyProgressStore = PregnancyProgressStore(preferencesStore: preferencesStore)
        let pregnancyProgressRepository = PregnancyProgressRepository(store: pregnancyProgressStore)
        let ultrasoundGalleryStore = UltrasoundGalleryStore(containerURL: containerURL)
        let ultrasoundGalleryRepository = UltrasoundGalleryRepository(store: ultrasoundGalleryStore)
        let bellyTrackingStore = BellyTrackingStore(containerURL: containerURL)
        let bellyTrackingRepository = BellyTrackingRepository(store: bellyTrackingStore)

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
            repository: pregnancyProgressRepository,
            calendar: .current
        )
        loadUltrasoundPhotosUseCase = LoadUltrasoundPhotosUseCase(
            repository: ultrasoundGalleryRepository
        )
        addUltrasoundPhotoUseCase = AddUltrasoundPhotoUseCase(
            repository: ultrasoundGalleryRepository
        )
        deleteUltrasoundPhotoUseCase = DeleteUltrasoundPhotoUseCase(
            repository: ultrasoundGalleryRepository
        )
        loadBellyTrackingTimelineUseCase = LoadBellyTrackingTimelineUseCase(
            repository: bellyTrackingRepository
        )
        loadBellyTrackingImageUseCase = LoadBellyTrackingImageUseCase(
            repository: bellyTrackingRepository
        )
        captureBellyTrackingPhotoUseCase = CaptureBellyTrackingPhotoUseCase(
            repository: bellyTrackingRepository
        )
        deleteBellyTrackingEntryUseCase = DeleteBellyTrackingEntryUseCase(
            repository: bellyTrackingRepository
        )
        loadBellyTrackingSettingsUseCase = LoadBellyTrackingSettingsUseCase(
            repository: bellyTrackingRepository
        )
        updateBellyTrackingSettingsUseCase = UpdateBellyTrackingSettingsUseCase(
            repository: bellyTrackingRepository
        )
        resolveBellyTrackingStatusUseCase = ResolveBellyTrackingStatusUseCase(
            calendar: .current
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
