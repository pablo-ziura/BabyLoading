import BellyTracking
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
        photoLibraryExporter: any PhotoLibraryExportingProtocol
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
        var failures: [GalleryLoadFailure] = []

        do {
            let progress = try await loadPregnancyProgressUseCase.execute(asOf: date)
            if case let .active(activeProgress) = progress {
                currentPregnancyWeek = activeProgress.gestationalAge.weeks
            } else {
                currentPregnancyWeek = nil
            }
        } catch {
            currentPregnancyWeek = nil
            failures.append(.pregnancyProgress)
        }

        do {
            ultrasoundPhotos = try await loadUltrasoundPhotosUseCase.execute()
        } catch {
            failures.append(.ultrasoundPhotos)
        }

        do {
            let trackingState = try await loadBellyTrackingState()
            apply(trackingState)
        } catch {
            failures.append(.bellyTracking)
        }

        loadingState = failures.isEmpty ? .loaded : .failed(failures)
    }

    public func importSelectedPhotos() async {
        let selectedItems = selectedPhotoPickerItems
        guard !selectedItems.isEmpty else { return }

        isImportingPhotos = true
        operationState = .idle
        var importFailed = false

        for selectedItem in selectedItems {
            do {
                guard let data = try await selectedItem.loadTransferable(type: Data.self) else {
                    importFailed = true
                    continue
                }
                let photo = try await addUltrasoundPhotoUseCase.execute(data: data)
                appendUltrasoundPhoto(photo)
            } catch {
                importFailed = true
            }
        }

        selectedPhotoPickerItems = []
        isImportingPhotos = false
        operationState = importFailed ? .failed(.importUltrasoundPhoto) : .idle
    }

    public func addUltrasoundPhoto(_ data: Data) async {
        do {
            let photo = try await addUltrasoundPhotoUseCase.execute(data: data)
            appendUltrasoundPhoto(photo)
            operationState = .idle
        } catch {
            operationState = .failed(.importUltrasoundPhoto)
        }
    }

    public func deleteUltrasoundPhoto(id: String) async {
        do {
            try await deleteUltrasoundPhotoUseCase.execute(id: id)
            ultrasoundPhotos.removeAll { $0.id == id }
            operationState = .idle
        } catch {
            operationState = .failed(.deleteUltrasoundPhoto)
        }
    }

    public func saveCapturedBellyTrackingPhoto(
        _ data: Data,
        capturedAt: Date = .now
    ) async -> Bool {
        let entry: BellyTrackingEntry
        do {
            entry = try await captureBellyTrackingPhotoUseCase.execute(
                data: data,
                capturedAt: capturedAt,
                pregnancyWeekAtCapture: currentPregnancyWeek
            )
        } catch {
            operationState = .failed(.captureBellyTrackingPhoto)
            return false
        }

        bellyTrackingEntries.append(entry)
        bellyTrackingEntries.sort { $0.capturedAt < $1.capturedAt }

        let exportData: Data
        do {
            let persistedData = try await loadBellyTrackingImageUseCase.execute(
                imageFileName: entry.imageFileName
            )
            bellyTrackingImageDataByEntryID[entry.id] = persistedData
            exportData = persistedData ?? data
            operationState = .idle
        } catch {
            exportData = data
            operationState = .failed(.loadBellyTrackingImage)
        }

        Task { @MainActor [weak self] in
            await self?.exportCapturedPhotoToPhotoLibrary(exportData)
        }
        return true
    }

    public func requestBellyTrackingDeletion(_ entry: BellyTrackingEntry) {
        activeAlert = .confirmBellyTrackingDeletion(entry)
    }

    public func deleteBellyTrackingEntry(id: UUID) async {
        do {
            try await deleteBellyTrackingEntryUseCase.execute(id: id)
            bellyTrackingEntries.removeAll { $0.id == id }
            bellyTrackingImageDataByEntryID[id] = nil
            operationState = .idle
        } catch {
            operationState = .failed(.deleteBellyTrackingPhoto)
        }
    }

    public func updateBellyTrackingCadence(intervalDays: Int) async {
        let settings = BellyTrackingSettings(intervalDays: intervalDays)
        do {
            try await updateBellyTrackingSettingsUseCase.execute(settings)
            bellyTrackingSettings = settings
            operationState = .idle
        } catch {
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
        switch await photoLibraryExporter.saveImageData(data) {
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
