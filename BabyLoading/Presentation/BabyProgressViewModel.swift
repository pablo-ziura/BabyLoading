import AppLocalization
import BellyTracking
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

enum BellyTrackingViewState: Equatable {
    case idle
    case loaded
    case failed(BellyTrackingViewError)
}

enum BellyTrackingViewError: Equatable {
    case loadFailed
    case captureFailed
    case deleteFailed
    case settingsUpdateFailed
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
    private(set) var bellyTrackingState: BellyTrackingViewState = .idle
    private(set) var appLanguage: AppLanguage
    let appVersion: String

    private let loadPregnancyProgressUseCase: any LoadPregnancyProgressUseCaseProtocol
    private let updateLastPeriodDateUseCase: any UpdateLastPeriodDateUseCaseProtocol
    private let widgetReloader: WidgetReloaderProtocol
    private var loadPregnancyWeekContentUseCase: any LoadPregnancyWeekContentUseCaseProtocol
    private var loadPregnancyTimelineUseCase: any LoadPregnancyTimelineUseCaseProtocol
    private let loadUltrasoundPhotosUseCase: any LoadUltrasoundPhotosUseCaseProtocol
    private let addUltrasoundPhotoUseCase: any AddUltrasoundPhotoUseCaseProtocol
    private let deleteUltrasoundPhotoUseCase: any DeleteUltrasoundPhotoUseCaseProtocol
    private let loadBellyTrackingTimelineUseCase: any LoadBellyTrackingTimelineUseCaseProtocol
    private let loadBellyTrackingImageUseCase: any LoadBellyTrackingImageUseCaseProtocol
    private let captureBellyTrackingPhotoUseCase: any CaptureBellyTrackingPhotoUseCaseProtocol
    private let deleteBellyTrackingEntryUseCase: any DeleteBellyTrackingEntryUseCaseProtocol
    private let loadBellyTrackingSettingsUseCase: any LoadBellyTrackingSettingsUseCaseProtocol
    private let updateBellyTrackingSettingsUseCase: any UpdateBellyTrackingSettingsUseCaseProtocol
    private let resolveBellyTrackingStatusUseCase: any ResolveBellyTrackingStatusUseCaseProtocol
    private var bellyTrackingImageDataByEntryID: [UUID: Data] = [:]

    var lastBellyTrackingEntry: BellyTrackingEntry? {
        bellyTrackingEntries.last
    }

    var lastBellyTrackingImageData: Data? {
        guard let lastBellyTrackingEntry else { return nil }
        return bellyTrackingImageDataByEntryID[lastBellyTrackingEntry.id]
    }

    func bellyTrackingStatus(asOf date: Date) -> BellyTrackingStatus {
        resolveBellyTrackingStatusUseCase.execute(
            settings: bellyTrackingSettings,
            lastCapture: lastBellyTrackingEntry?.capturedAt,
            asOf: date
        )
    }

    init(
        loadPregnancyProgressUseCase: any LoadPregnancyProgressUseCaseProtocol,
        updateLastPeriodDateUseCase: any UpdateLastPeriodDateUseCaseProtocol,
        loadPregnancyWeekContentUseCase: any LoadPregnancyWeekContentUseCaseProtocol,
        loadPregnancyTimelineUseCase: any LoadPregnancyTimelineUseCaseProtocol,
        loadUltrasoundPhotosUseCase: any LoadUltrasoundPhotosUseCaseProtocol,
        addUltrasoundPhotoUseCase: any AddUltrasoundPhotoUseCaseProtocol,
        deleteUltrasoundPhotoUseCase: any DeleteUltrasoundPhotoUseCaseProtocol,
        loadBellyTrackingTimelineUseCase: any LoadBellyTrackingTimelineUseCaseProtocol,
        loadBellyTrackingImageUseCase: any LoadBellyTrackingImageUseCaseProtocol,
        captureBellyTrackingPhotoUseCase: any CaptureBellyTrackingPhotoUseCaseProtocol,
        deleteBellyTrackingEntryUseCase: any DeleteBellyTrackingEntryUseCaseProtocol,
        loadBellyTrackingSettingsUseCase: any LoadBellyTrackingSettingsUseCaseProtocol,
        updateBellyTrackingSettingsUseCase: any UpdateBellyTrackingSettingsUseCaseProtocol,
        resolveBellyTrackingStatusUseCase: any ResolveBellyTrackingStatusUseCaseProtocol,
        initialLanguage: AppLanguage,
        appVersion: String,
        widgetReloader: WidgetReloaderProtocol
    ) {
        self.loadPregnancyProgressUseCase = loadPregnancyProgressUseCase
        self.updateLastPeriodDateUseCase = updateLastPeriodDateUseCase
        self.loadPregnancyWeekContentUseCase = loadPregnancyWeekContentUseCase
        self.loadPregnancyTimelineUseCase = loadPregnancyTimelineUseCase
        self.loadUltrasoundPhotosUseCase = loadUltrasoundPhotosUseCase
        self.addUltrasoundPhotoUseCase = addUltrasoundPhotoUseCase
        self.deleteUltrasoundPhotoUseCase = deleteUltrasoundPhotoUseCase
        self.loadBellyTrackingTimelineUseCase = loadBellyTrackingTimelineUseCase
        self.loadBellyTrackingImageUseCase = loadBellyTrackingImageUseCase
        self.captureBellyTrackingPhotoUseCase = captureBellyTrackingPhotoUseCase
        self.deleteBellyTrackingEntryUseCase = deleteBellyTrackingEntryUseCase
        self.loadBellyTrackingSettingsUseCase = loadBellyTrackingSettingsUseCase
        self.updateBellyTrackingSettingsUseCase = updateBellyTrackingSettingsUseCase
        self.resolveBellyTrackingStatusUseCase = resolveBellyTrackingStatusUseCase
        self.widgetReloader = widgetReloader
        appLanguage = initialLanguage
        self.appVersion = appVersion

        lastPeriodDate = .now
        allWeekContent = []
        bellyTrackingSettings = .default
        estimatedDueDate = nil
        daysRemaining = nil
        pregnancyWeek = nil
        currentWeekContent = nil
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

    func reloadBellyTrackingState() async {
        do {
            let entries = try await loadBellyTrackingTimelineUseCase.execute()
            let settings = try await loadBellyTrackingSettingsUseCase.execute()
            var imageDataByEntryID: [UUID: Data] = [:]

            for entry in entries {
                if let data = try await loadBellyTrackingImageUseCase.execute(
                    imageFileName: entry.imageFileName
                ) {
                    imageDataByEntryID[entry.id] = data
                }
            }

            bellyTrackingEntries = entries
            bellyTrackingSettings = settings
            bellyTrackingImageDataByEntryID = imageDataByEntryID
            bellyTrackingState = .loaded
        } catch {
            bellyTrackingState = .failed(.loadFailed)
        }
    }

    func saveBellyTrackingPhoto(_ data: Data) async -> Bool {
        let savedEntry: BellyTrackingEntry
        do {
            savedEntry = try await captureBellyTrackingPhotoUseCase.execute(
                data: data,
                capturedAt: .now,
                pregnancyWeekAtCapture: pregnancyWeek
            )
        } catch {
            bellyTrackingState = .failed(.captureFailed)
            return false
        }

        bellyTrackingEntries.append(savedEntry)
        bellyTrackingEntries.sort { $0.capturedAt < $1.capturedAt }

        do {
            bellyTrackingImageDataByEntryID[savedEntry.id] = try await loadBellyTrackingImageUseCase.execute(
                imageFileName: savedEntry.imageFileName
            )
            bellyTrackingState = .loaded
        } catch {
            bellyTrackingState = .failed(.loadFailed)
        }
        return true
    }

    func deleteBellyTrackingEntry(id: UUID) async {
        do {
            try await deleteBellyTrackingEntryUseCase.execute(id: id)
            bellyTrackingEntries.removeAll { $0.id == id }
            bellyTrackingImageDataByEntryID[id] = nil
            bellyTrackingState = .loaded
        } catch {
            bellyTrackingState = .failed(.deleteFailed)
        }
    }

    func updateBellyTrackingCadence(intervalDays: Int) async {
        let settings = BellyTrackingSettings(intervalDays: intervalDays)
        do {
            try await updateBellyTrackingSettingsUseCase.execute(settings)
            bellyTrackingSettings = settings
            bellyTrackingState = .loaded
        } catch {
            bellyTrackingState = .failed(.settingsUpdateFailed)
        }
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
}
