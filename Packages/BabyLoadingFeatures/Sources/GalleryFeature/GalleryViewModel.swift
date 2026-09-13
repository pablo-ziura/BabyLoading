import BellyTracking
import CloudBackup
import Foundation
import Observation
import PhotosUI
import PregnancyProgress
import SwiftUI
import UltrasoundGallery

public enum GalleryLoadFailure: Equatable, Sendable {
    case pregnancyProgress
    case ultrasoundPhotos
    case bellyTracking
}

public enum GalleryLoadingState: Equatable, Sendable {
    case idle
    case loaded
    case failed([GalleryLoadFailure])
}

public enum GalleryOperation: Equatable, Sendable {
    case importUltrasoundPhoto
    case deleteUltrasoundPhoto
    case captureBellyTrackingPhoto
    case loadBellyTrackingImage
    case deleteBellyTrackingPhoto
    case updateTrackingCadence
}

public enum GalleryOperationState: Equatable, Sendable {
    case idle
    case failed(GalleryOperation)
}

public enum GalleryAlertState: Identifiable, Equatable, Sendable {
    case confirmBellyTrackingDeletion(BellyTrackingEntry)
    case photoLibraryPermissionDenied
    case photoLibraryExportFailed

    public var id: String {
        switch self {
        case let .confirmBellyTrackingDeletion(entry):
            "delete-\(entry.id.uuidString)"
        case .photoLibraryPermissionDenied:
            "photo-library-permission-denied"
        case .photoLibraryExportFailed:
            "photo-library-export-failed"
        }
    }
}

@MainActor
@Observable
public final class GalleryViewModel {
    public private(set) var backupState = BackupState()
    @ObservationIgnored private let retryBackupUseCase: RetryBackupUseCase
    @ObservationIgnored private var backupGeneration = UUID()
    @ObservationIgnored private var retryBackupTask: Task<Void, Never>?
    public var selectedPhotoPickerItems: [PhotosPickerItem] = []
    public private(set) var ultrasoundPhotos: [UltrasoundPhoto] = []
    public private(set) var bellyTrackingEntries: [BellyTrackingEntry] = []
    public private(set) var bellyTrackingSettings: BellyTrackingSettings = .default
    public private(set) var activeAlert: GalleryAlertState?
    public private(set) var loadingState: GalleryLoadingState = .idle
    public private(set) var operationState: GalleryOperationState = .idle
    public private(set) var isImportingPhotos = false

    private var bellyTrackingImageDataByEntryID: [UUID: Data] = [:]
    @ObservationIgnored private var currentPregnancyWeek: Int?

    @ObservationIgnored private let loadPregnancyProgressUseCase: any LoadPregnancyProgressUseCaseProtocol
    @ObservationIgnored private let loadUltrasoundPhotosUseCase: any LoadUltrasoundPhotosUseCaseProtocol
    @ObservationIgnored private let addUltrasoundPhotoUseCase: any AddUltrasoundPhotoUseCaseProtocol
    @ObservationIgnored private let deleteUltrasoundPhotoUseCase: any DeleteUltrasoundPhotoUseCaseProtocol
    @ObservationIgnored private let loadBellyTrackingTimelineUseCase: any LoadBellyTrackingTimelineUseCaseProtocol
    @ObservationIgnored private let loadBellyTrackingImageUseCase: any LoadBellyTrackingImageUseCaseProtocol
    @ObservationIgnored private let captureBellyTrackingPhotoUseCase: any CaptureBellyTrackingPhotoUseCaseProtocol
    @ObservationIgnored private let deleteBellyTrackingEntryUseCase: any DeleteBellyTrackingEntryUseCaseProtocol
    @ObservationIgnored private let loadBellyTrackingSettingsUseCase: any LoadBellyTrackingSettingsUseCaseProtocol
    @ObservationIgnored private let updateBellyTrackingSettingsUseCase: any UpdateBellyTrackingSettingsUseCaseProtocol
    @ObservationIgnored private let resolveBellyTrackingStatusUseCase: any ResolveBellyTrackingStatusUseCaseProtocol
    @ObservationIgnored private let photoLibraryExporter: any PhotoLibraryExportingProtocol

    public init(
        loadPregnancyProgressUseCase: any LoadPregnancyProgressUseCaseProtocol,
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
        photoLibraryExporter: any PhotoLibraryExportingProtocol,
        retryBackupUseCase: RetryBackupUseCase
    ) {
        self.loadPregnancyProgressUseCase = loadPregnancyProgressUseCase
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
        self.photoLibraryExporter = photoLibraryExporter
        self.retryBackupUseCase = retryBackupUseCase
    }

    public func applyBackupState(_ state: BackupState) {
        if state.profileID != backupState.profileID {
            backupGeneration = UUID()
            ultrasoundPhotos = []
            bellyTrackingEntries = []
            bellyTrackingImageDataByEntryID = [:]
            selectedPhotoPickerItems = []
            activeAlert = nil
            currentPregnancyWeek = nil
            bellyTrackingSettings = .default
            operationState = .idle
            loadingState = .idle
        }
        backupState = state
    }

    public func retryBackup() {
        guard retryBackupTask == nil else { return }
        retryBackupTask = Task { [weak self] in
            guard let self else { return }
            defer { self.retryBackupTask = nil }
            do { try await self.retryBackupUseCase.execute() } catch {
                self.backupState.failure = (error as? BackupFailure) ?? .storage
            }
        }
    }

    public func backupRecord(origin: BackupPhotoOrigin, sourceID: String) -> BackupRecord? {
        backupState.records.first { $0.remote.origin == origin && $0.remote.sourceID == sourceID }
    }

    public var lastBellyTrackingEntry: BellyTrackingEntry? {
        bellyTrackingEntries.last
    }

    public var lastBellyTrackingImageData: Data? {
        guard let lastBellyTrackingEntry else { return nil }
        return bellyTrackingImageDataByEntryID[lastBellyTrackingEntry.id]
    }

    public func bellyTrackingImageData(for entry: BellyTrackingEntry) -> Data? {
        bellyTrackingImageDataByEntryID[entry.id]
    }

    public func bellyTrackingStatus(asOf date: Date) -> BellyTrackingStatus {
        resolveBellyTrackingStatusUseCase.execute(
            settings: bellyTrackingSettings,
            lastCapture: lastBellyTrackingEntry?.capturedAt,
            asOf: date
        )
    }

    public func reload(asOf date: Date = .now) async {
        let generation = backupGeneration
        var failures: [GalleryLoadFailure] = []

        do {
            let progress = try await loadPregnancyProgressUseCase.execute(asOf: date)
            guard generation == backupGeneration else { return }
            if case let .active(activeProgress) = progress {
                currentPregnancyWeek = activeProgress.gestationalAge.weeks
            } else {
                currentPregnancyWeek = nil
            }
        } catch {
            guard generation == backupGeneration else { return }
            currentPregnancyWeek = nil
            failures.append(.pregnancyProgress)
        }

        do {
            let photos = try await loadUltrasoundPhotosUseCase.execute()
            guard generation == backupGeneration else { return }
            ultrasoundPhotos = photos
        } catch {
            failures.append(.ultrasoundPhotos)
        }

        do {
            let trackingState = try await loadBellyTrackingState()
            guard generation == backupGeneration else { return }
            apply(trackingState)
        } catch {
            failures.append(.bellyTracking)
        }

        guard generation == backupGeneration else { return }
        loadingState = failures.isEmpty ? .loaded : .failed(failures)
    }

    public func importSelectedPhotos() async {
        let selectedItems = selectedPhotoPickerItems
        let generation = backupGeneration
        guard !selectedItems.isEmpty, !backupState.isWorking else { return }
        defer { isImportingPhotos = false }

        isImportingPhotos = true
        operationState = .idle
        var importFailed = false

        for selectedItem in selectedItems {
            do {
                guard let data = try await selectedItem.loadTransferable(type: Data.self) else {
                    importFailed = true
                    continue
                }
                guard generation == backupGeneration, !backupState.isWorking else { return }
                let photo = try await addUltrasoundPhotoUseCase.execute(data: data)
                guard generation == backupGeneration else { return }
                appendUltrasoundPhoto(photo)
            } catch {
                importFailed = true
            }
        }

        guard generation == backupGeneration else { return }
        selectedPhotoPickerItems = []
        isImportingPhotos = false
        operationState = importFailed ? .failed(.importUltrasoundPhoto) : .idle
    }

    public func addUltrasoundPhoto(_ data: Data) async {
        guard !backupState.isWorking else { return }
        let generation = backupGeneration
        do {
            let photo = try await addUltrasoundPhotoUseCase.execute(data: data)
            guard generation == backupGeneration else { return }
            appendUltrasoundPhoto(photo)
            operationState = .idle
        } catch {
            guard generation == backupGeneration else { return }
            operationState = .failed(.importUltrasoundPhoto)
        }
    }

    public func deleteUltrasoundPhoto(id: String) async {
        guard !backupState.isWorking else { return }
        let generation = backupGeneration
        do {
            try await deleteUltrasoundPhotoUseCase.execute(id: id)
            guard generation == backupGeneration else { return }
            ultrasoundPhotos.removeAll { $0.id == id }
            operationState = .idle
        } catch {
            guard generation == backupGeneration else { return }
            operationState = .failed(.deleteUltrasoundPhoto)
        }
    }

    public func saveCapturedBellyTrackingPhoto(
        _ data: Data,
        capturedAt: Date = .now
    ) async -> Bool {
        guard !backupState.isWorking else { return false }
        let generation = backupGeneration
        let entry: BellyTrackingEntry
        do {
            entry = try await captureBellyTrackingPhotoUseCase.execute(
                data: data,
                capturedAt: capturedAt,
                pregnancyWeekAtCapture: currentPregnancyWeek
            )
        } catch {
            guard generation == backupGeneration else { return false }
            operationState = .failed(.captureBellyTrackingPhoto)
            return false
        }

        guard generation == backupGeneration else { return true }
        bellyTrackingEntries.append(entry)
        bellyTrackingEntries.sort { $0.capturedAt < $1.capturedAt }

        let exportData: Data
        do {
            let persistedData = try await loadBellyTrackingImageUseCase.execute(
                imageFileName: entry.imageFileName
            )
            guard generation == backupGeneration else { return true }
            bellyTrackingImageDataByEntryID[entry.id] = persistedData
            exportData = persistedData ?? data
            operationState = .idle
        } catch {
            guard generation == backupGeneration else { return true }
            exportData = data
            operationState = .failed(.loadBellyTrackingImage)
        }

        Task { @MainActor [weak self] in
            guard let self, generation == self.backupGeneration else { return }
            await self.exportCapturedPhotoToPhotoLibrary(exportData)
        }
        return true
    }

    public func requestBellyTrackingDeletion(_ entry: BellyTrackingEntry) {
        activeAlert = .confirmBellyTrackingDeletion(entry)
    }

    public func deleteBellyTrackingEntry(id: UUID) async {
        guard !backupState.isWorking else { return }
        let generation = backupGeneration
        do {
            try await deleteBellyTrackingEntryUseCase.execute(id: id)
            guard generation == backupGeneration else { return }
            bellyTrackingEntries.removeAll { $0.id == id }
            bellyTrackingImageDataByEntryID[id] = nil
            operationState = .idle
        } catch {
            guard generation == backupGeneration else { return }
            operationState = .failed(.deleteBellyTrackingPhoto)
        }
    }

    public func updateBellyTrackingCadence(intervalDays: Int) async {
        guard !backupState.isWorking else { return }
        let generation = backupGeneration
        let settings = BellyTrackingSettings(intervalDays: intervalDays)
        do {
            try await updateBellyTrackingSettingsUseCase.execute(settings)
            guard generation == backupGeneration else { return }
            bellyTrackingSettings = settings
            operationState = .idle
        } catch {
            guard generation == backupGeneration else { return }
            operationState = .failed(.updateTrackingCadence)
        }
    }

    public func clearActiveAlert() {
        activeAlert = nil
    }

    private func loadBellyTrackingState() async throws -> BellyTrackingViewData {
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

        return BellyTrackingViewData(
            entries: entries,
            settings: settings,
            imageDataByEntryID: imageDataByEntryID
        )
    }

    private func apply(_ viewData: BellyTrackingViewData) {
        bellyTrackingEntries = viewData.entries
        bellyTrackingSettings = viewData.settings
        bellyTrackingImageDataByEntryID = viewData.imageDataByEntryID
    }

    private func appendUltrasoundPhoto(_ photo: UltrasoundPhoto) {
        if let existingIndex = ultrasoundPhotos.firstIndex(where: { $0.id == photo.id }) {
            ultrasoundPhotos[existingIndex] = photo
        } else {
            ultrasoundPhotos.append(photo)
        }
    }

    private func exportCapturedPhotoToPhotoLibrary(_ data: Data) async {
        let generation = backupGeneration
        let result = await photoLibraryExporter.saveImageData(data)
        guard generation == backupGeneration else { return }
        switch result {
        case .saved:
            break
        case .permissionDenied:
            activeAlert = .photoLibraryPermissionDenied
        case .failed:
            activeAlert = .photoLibraryExportFailed
        }
    }
}

private struct BellyTrackingViewData {
    let entries: [BellyTrackingEntry]
    let settings: BellyTrackingSettings
    let imageDataByEntryID: [UUID: Data]
}
