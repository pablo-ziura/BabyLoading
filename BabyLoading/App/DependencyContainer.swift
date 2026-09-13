import AppLocalization
import AppPreferences
import BabyLoadingCloud
import BabyLoadingInfrastructure
import BellyTracking
import CloudBackup
import FirebaseCore
import Foundation
import GoogleSignIn
import PregnancyContent
import PregnancyProgress
import UIKit
import UltrasoundGallery

@MainActor
final class DependencyContainer {
    let backupRuntime: BackupRuntime
    let backupUseCases: BackupAccountUseCases
    let widgetReloader: WidgetReloaderProtocol
    let resolveAppLanguageUseCase: any ResolveAppLanguageUseCaseProtocol
    let loadAppVersionUseCase: any LoadAppVersionUseCaseProtocol
    let loadPregnancyProgressUseCase: any LoadPregnancyProgressUseCaseProtocol
    let updateLastPeriodDateUseCase: any UpdateLastPeriodDateUseCaseProtocol
    let calculateDueDateUseCase: any CalculateDueDateUseCaseProtocol
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

    convenience init() {
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

        self.init(
            preferencesStore: preferencesStore, containerURL: containerURL,
            widgetReloader: DefaultWidgetReloader(), makeBackupServices: Self.makeBackupServices
        )
    }

    init(
        preferencesStore: UserDefaultsPreferencesStore,
        containerURL: URL,
        widgetReloader: any WidgetReloaderProtocol,
        makeBackupServices: @escaping @MainActor (BackupLocalStore, URL) throws -> BackupServices
    ) {
        let resolveAppLanguageUseCase = ResolveAppLanguageUseCase()
        let initialLanguage = resolveAppLanguageUseCase.execute(
            preferredLanguages: Bundle.main.preferredLocalizations + Locale.preferredLanguages
        )

        let pregnancyProgressStore = PregnancyProgressStore(preferencesStore: preferencesStore)
        let ultrasoundGalleryStore = UltrasoundGalleryStore(containerURL: containerURL)
        let bellyTrackingStore = BellyTrackingStore(containerURL: containerURL)
        let backupStore = BackupLocalStore(containerURL: containerURL)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        backupRuntime = BackupRuntime(
            localStore: backupStore,
            initializeLocal: InitializeBackupUseCase(
                store: backupStore, legacyProgress: pregnancyProgressStore, legacyGallery: ultrasoundGalleryStore,
                legacyTracking: bellyTrackingStore, calendar: calendar, legacyContainerURL: containerURL
            ),
            projectionStore: pregnancyProgressStore, calendar: calendar,
            makeServices: { try makeBackupServices(backupStore, containerURL) }
        )
        backupUseCases = BackupAccountUseCases(operations: backupRuntime)
        let pregnancyProgressRepository = PregnancyProgressRepository(
            store: AccountPregnancyProgressStore(store: backupStore, calendar: calendar)
        )
        let ultrasoundGalleryRepository = UltrasoundGalleryRepository(store: AccountUltrasoundStore(store: backupStore))
        let bellyTrackingRepository = BellyTrackingRepository(store: AccountBellyTrackingStore(store: backupStore))

        self.widgetReloader = widgetReloader
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
        calculateDueDateUseCase = CalculateDueDateUseCase(calendar: .current)
        loadUltrasoundPhotosUseCase = LoadUltrasoundPhotosUseCase(
            repository: ultrasoundGalleryRepository
        )
        addUltrasoundPhotoUseCase = AddUltrasoundPhotoUseCase(
            validator: UltrasoundImageValidator(policy: .standard),
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

    private static func makeBackupServices(localStore: BackupLocalStore, containerURL: URL) throws -> BackupServices {
        guard let app = FirebaseApp.app() else { throw BackupFailure.unavailable }
        return try FirebaseBackupFactory.makeServices(
            app: app, localStore: localStore,
            preparer: BackupJPEGPreparer(validator: UltrasoundImageValidator(policy: .standard)),
            temporaryDirectory: containerURL.appendingPathComponent("backup-transfers", isDirectory: true),
            googleSignIn: GIDSignIn.sharedInstance,
            presenter: {
                let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
                    .first { $0.activationState == .foregroundActive }
                var controller = scene?.windows.first(where: \.isKeyWindow)?.rootViewController
                while let presented = controller?.presentedViewController { controller = presented }
                return controller
            }
        )
    }

    func handleOpenURL(_ url: URL) { _ = GIDSignIn.sharedInstance.handle(url) }

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
