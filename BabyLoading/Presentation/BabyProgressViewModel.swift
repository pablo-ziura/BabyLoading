import AppLocalization
import Foundation
import Observation
import PregnancyContent
import PregnancyProgress
import UltrasoundGallery

enum PregnancyProgressViewState: Equatable {
    case idle
    case loaded
    case failed(PregnancyProgressViewError)
}

enum PregnancyProgressViewError: Equatable {
    case loadFailed
    case updateFailed
}

enum UltrasoundGalleryViewState: Equatable {
    case idle
    case loaded
    case failed(UltrasoundGalleryViewError)
}

enum UltrasoundGalleryViewError: Equatable {
    case loadFailed
    case addFailed
    case deleteFailed
}

@Observable
@MainActor
class BabyProgressViewModel {
    var lastPeriodDate: Date
    var estimatedDueDate: Date?
    var daysRemaining: Int?
    var pregnancyWeek: Int?
    var currentWeekContent: WeekContent?
    var allWeekContent: [WeekContent]
    var ultrasoundPhotos: [UltrasoundPhoto] = []
    var bellyTrackingEntries: [BellyTrackingEntry] = []
    var bellyTrackingSettings: BellyTrackingSettings
    var showingPhotoPicker = false
    private(set) var pregnancyProgressState: PregnancyProgressViewState = .idle
    private(set) var ultrasoundGalleryState: UltrasoundGalleryViewState = .idle
    private(set) var appLanguage: AppLanguage
    let appVersion: String

    private let repository: BabyProgressRepositoryProtocol
    private let loadPregnancyProgressUseCase: any LoadPregnancyProgressUseCaseProtocol
    private let updateLastPeriodDateUseCase: any UpdateLastPeriodDateUseCaseProtocol
    private let widgetReloader: WidgetReloaderProtocol
    private var loadPregnancyWeekContentUseCase: any LoadPregnancyWeekContentUseCaseProtocol
    private var loadPregnancyTimelineUseCase: any LoadPregnancyTimelineUseCaseProtocol
    private let loadUltrasoundPhotosUseCase: any LoadUltrasoundPhotosUseCaseProtocol
    private let addUltrasoundPhotoUseCase: any AddUltrasoundPhotoUseCaseProtocol
    private let deleteUltrasoundPhotoUseCase: any DeleteUltrasoundPhotoUseCaseProtocol
    private var bellyTrackingImageDataByEntryID: [UUID: Data] = [:]

    var lastBellyTrackingEntry: BellyTrackingEntry? {
        bellyTrackingEntries.last
    }

    var lastBellyTrackingImageData: Data? {
        guard let lastBellyTrackingEntry else { return nil }
        return bellyTrackingImageDataByEntryID[lastBellyTrackingEntry.id]
    }

    func bellyTrackingStatus(asOf date: Date) -> BellyTrackingStatus {
        bellyTrackingSettings.trackingStatus(
            lastCapture: lastBellyTrackingEntry?.capturedAt,
            asOf: date
        )
    }

    init(
        repository: BabyProgressRepositoryProtocol,
        loadPregnancyProgressUseCase: any LoadPregnancyProgressUseCaseProtocol,
        updateLastPeriodDateUseCase: any UpdateLastPeriodDateUseCaseProtocol,
        loadPregnancyWeekContentUseCase: any LoadPregnancyWeekContentUseCaseProtocol,
        loadPregnancyTimelineUseCase: any LoadPregnancyTimelineUseCaseProtocol,
        loadUltrasoundPhotosUseCase: any LoadUltrasoundPhotosUseCaseProtocol,
        addUltrasoundPhotoUseCase: any AddUltrasoundPhotoUseCaseProtocol,
        deleteUltrasoundPhotoUseCase: any DeleteUltrasoundPhotoUseCaseProtocol,
        initialLanguage: AppLanguage,
        appVersion: String,
        widgetReloader: WidgetReloaderProtocol
    ) {
        self.repository = repository
        self.loadPregnancyProgressUseCase = loadPregnancyProgressUseCase
        self.updateLastPeriodDateUseCase = updateLastPeriodDateUseCase
        self.loadPregnancyWeekContentUseCase = loadPregnancyWeekContentUseCase
        self.loadPregnancyTimelineUseCase = loadPregnancyTimelineUseCase
        self.loadUltrasoundPhotosUseCase = loadUltrasoundPhotosUseCase
        self.addUltrasoundPhotoUseCase = addUltrasoundPhotoUseCase
        self.deleteUltrasoundPhotoUseCase = deleteUltrasoundPhotoUseCase
        self.widgetReloader = widgetReloader
        appLanguage = initialLanguage
        self.appVersion = appVersion

        lastPeriodDate = .now
        allWeekContent = []
        bellyTrackingSettings = self.repository.fetchBellyTrackingSettings()
        estimatedDueDate = nil
        daysRemaining = nil
        pregnancyWeek = nil
        currentWeekContent = nil

        reloadBellyTrackingState()
    }

    func reloadProgress(asOf date: Date = .now) async {
        do {
            let progress = try await loadPregnancyProgressUseCase.execute(asOf: date)
            await apply(progress)
            pregnancyProgressState = .loaded
        } catch {
            pregnancyProgressState = .failed(.loadFailed)
        }
    }

    func reloadContent() async {
        allWeekContent = await loadPregnancyTimelineUseCase.execute()

        if let pregnancyWeek {
            currentWeekContent = await loadPregnancyWeekContentUseCase.execute(week: pregnancyWeek)
        }
    }

    func updateDate(_ date: Date) async {
        do {
            try await updateLastPeriodDateUseCase.execute(date)
            lastPeriodDate = date
            await reloadProgress()
            widgetReloader.reloadAllTimelines()
        } catch {
            pregnancyProgressState = .failed(.updateFailed)
        }
    }

    @discardableResult
    func applyContentLanguage(
        _ language: AppLanguage,
        loadPregnancyWeekContentUseCase: any LoadPregnancyWeekContentUseCaseProtocol,
        loadPregnancyTimelineUseCase: any LoadPregnancyTimelineUseCaseProtocol
    ) async -> Bool {
        guard language != appLanguage else {
            return false
        }

        appLanguage = language
        self.loadPregnancyWeekContentUseCase = loadPregnancyWeekContentUseCase
        self.loadPregnancyTimelineUseCase = loadPregnancyTimelineUseCase
        await reloadContent()
        await reloadProgress()
        return true
    }

    // MARK: - Ultrasound gallery

    func reloadUltrasoundPhotos() async {
        do {
            ultrasoundPhotos = try await loadUltrasoundPhotosUseCase.execute()
            ultrasoundGalleryState = .loaded
        } catch {
            ultrasoundGalleryState = .failed(.loadFailed)
        }
    }

    func addUltrasoundPhoto(_ data: Data) async {
        do {
            let photo = try await addUltrasoundPhotoUseCase.execute(data: data)
            ultrasoundPhotos.append(photo)
            ultrasoundGalleryState = .loaded
        } catch {
            ultrasoundGalleryState = .failed(.addFailed)
        }
    }

    func deleteUltrasoundPhoto(id: String) async {
        do {
            try await deleteUltrasoundPhotoUseCase.execute(id: id)
            ultrasoundPhotos.removeAll { $0.id == id }
            ultrasoundGalleryState = .loaded
        } catch {
            ultrasoundGalleryState = .failed(.deleteFailed)
        }
    }

    func saveBellyTrackingPhoto(_ data: Data) -> Bool {
        let savedEntry = repository.saveBellyTrackingPhoto(
            data: data,
            capturedAt: .now,
            pregnancyWeekAtCapture: pregnancyWeek
        )

        reloadBellyTrackingState()
        return savedEntry != nil
    }

    func deleteBellyTrackingEntry(id: UUID) {
        repository.deleteBellyTrackingEntry(id: id)
        reloadBellyTrackingState()
    }

    func updateBellyTrackingCadence(intervalDays: Int) {
        let settings = BellyTrackingSettings(intervalDays: intervalDays)
        repository.saveBellyTrackingSettings(settings)
        reloadBellyTrackingState()
    }

    func bellyTrackingImageData(for entry: BellyTrackingEntry) -> Data? {
        bellyTrackingImageDataByEntryID[entry.id]
    }

    private func apply(_ progress: PregnancyProgress?) async {
        guard let progress else {
            estimatedDueDate = nil
            daysRemaining = nil
            pregnancyWeek = nil
            currentWeekContent = nil
            return
        }

        lastPeriodDate = progress.lastPeriodDate
        estimatedDueDate = progress.dueDate
        daysRemaining = progress.daysUntilDueDate
        pregnancyWeek = progress.currentWeek
        currentWeekContent = await loadPregnancyWeekContentUseCase.execute(week: progress.currentWeek)
    }

    private func reloadBellyTrackingState() {
        bellyTrackingEntries = repository.fetchBellyTrackingEntries()
        bellyTrackingSettings = repository.fetchBellyTrackingSettings()
        bellyTrackingImageDataByEntryID = Dictionary(
            uniqueKeysWithValues: bellyTrackingEntries.compactMap { entry in
                guard let data = repository.fetchBellyTrackingImageData(for: entry.imageFileName) else {
                    return nil
                }

                return (entry.id, data)
            }
        )
    }
}
