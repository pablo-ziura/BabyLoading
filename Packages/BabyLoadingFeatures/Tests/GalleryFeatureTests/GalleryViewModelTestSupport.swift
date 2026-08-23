@testable import GalleryFeature
import BellyTracking
import Foundation
import Observation
import PregnancyProgress
import UltrasoundGallery

@MainActor
final class GalleryViewModelTestContext {
    let loadProgressUseCase: GalleryLoadPregnancyProgressUseCaseMock
    let loadUltrasoundPhotosUseCase: GalleryLoadUltrasoundPhotosUseCaseMock
    let addUltrasoundPhotoUseCase: GalleryAddUltrasoundPhotoUseCaseMock
    let deleteUltrasoundPhotoUseCase: GalleryDeleteUltrasoundPhotoUseCaseMock
    let bellyTrackingRepository: GalleryBellyTrackingRepositoryMock
    let photoLibraryExporter: GalleryPhotoLibraryExporterStub
    let viewModel: GalleryViewModel

    init(calendar: Calendar = makeGalleryCalendar()) {
        let loadProgressUseCase = GalleryLoadPregnancyProgressUseCaseMock()
        let loadUltrasoundPhotosUseCase = GalleryLoadUltrasoundPhotosUseCaseMock()
        let addUltrasoundPhotoUseCase = GalleryAddUltrasoundPhotoUseCaseMock()
        let deleteUltrasoundPhotoUseCase = GalleryDeleteUltrasoundPhotoUseCaseMock()
        let bellyTrackingRepository = GalleryBellyTrackingRepositoryMock()
        let photoLibraryExporter = GalleryPhotoLibraryExporterStub()

        self.loadProgressUseCase = loadProgressUseCase
        self.loadUltrasoundPhotosUseCase = loadUltrasoundPhotosUseCase
        self.addUltrasoundPhotoUseCase = addUltrasoundPhotoUseCase
        self.deleteUltrasoundPhotoUseCase = deleteUltrasoundPhotoUseCase
        self.bellyTrackingRepository = bellyTrackingRepository
        self.photoLibraryExporter = photoLibraryExporter
        viewModel = GalleryViewModel(
            loadPregnancyProgressUseCase: loadProgressUseCase,
            loadUltrasoundPhotosUseCase: loadUltrasoundPhotosUseCase,
            addUltrasoundPhotoUseCase: addUltrasoundPhotoUseCase,
            deleteUltrasoundPhotoUseCase: deleteUltrasoundPhotoUseCase,
            loadBellyTrackingTimelineUseCase: LoadBellyTrackingTimelineUseCase(repository: bellyTrackingRepository),
            loadBellyTrackingImageUseCase: LoadBellyTrackingImageUseCase(repository: bellyTrackingRepository),
            captureBellyTrackingPhotoUseCase: CaptureBellyTrackingPhotoUseCase(repository: bellyTrackingRepository),
            deleteBellyTrackingEntryUseCase: DeleteBellyTrackingEntryUseCase(repository: bellyTrackingRepository),
            loadBellyTrackingSettingsUseCase: LoadBellyTrackingSettingsUseCase(repository: bellyTrackingRepository),
            updateBellyTrackingSettingsUseCase: UpdateBellyTrackingSettingsUseCase(repository: bellyTrackingRepository),
            resolveBellyTrackingStatusUseCase: ResolveBellyTrackingStatusUseCase(calendar: calendar),
            photoLibraryExporter: photoLibraryExporter
        )
    }
}

actor GalleryPhotoLibraryExporterStub: PhotoLibraryExportingProtocol {
    private var result: PhotoLibraryExportResult = .saved
    private var savedData: [Data] = []
    private var shouldSuspendNextSave = false
    private var suspendedSaveContinuations: [CheckedContinuation<Void, Never>] = []
    private var saveCountWaiters: [GalleryPhotoLibrarySaveCountWaiter] = []

    func saveImageData(_ data: Data) async -> PhotoLibraryExportResult {
        let result = result
        savedData.append(data)
        resumeSatisfiedSaveCountWaiters()

        if shouldSuspendNextSave {
            shouldSuspendNextSave = false
            await withCheckedContinuation { continuation in
                suspendedSaveContinuations.append(continuation)
            }
        }

        return result
    }

    func setResult(_ result: PhotoLibraryExportResult) {
        self.result = result
    }

    func suspendNextSave() {
        shouldSuspendNextSave = true
    }

    func resumeNextSave() {
        guard !suspendedSaveContinuations.isEmpty else { return }
        suspendedSaveContinuations.removeFirst().resume()
    }

    func waitForSaveCount(_ count: Int) async {
        guard savedData.count < count else { return }
        await withCheckedContinuation { continuation in
            saveCountWaiters.append(
                GalleryPhotoLibrarySaveCountWaiter(
                    expectedCount: count,
                    continuation: continuation
                )
            )
        }
    }

    func snapshot() -> GalleryPhotoLibraryExportSnapshot {
        GalleryPhotoLibraryExportSnapshot(savedData: savedData)
    }

    private func resumeSatisfiedSaveCountWaiters() {
        let satisfiedWaiters = saveCountWaiters.filter { savedData.count >= $0.expectedCount }
        saveCountWaiters.removeAll { savedData.count >= $0.expectedCount }
        satisfiedWaiters.forEach { $0.continuation.resume() }
    }
}

struct GalleryPhotoLibraryExportSnapshot: Sendable {
    let savedData: [Data]
}

private struct GalleryPhotoLibrarySaveCountWaiter {
    let expectedCount: Int
    let continuation: CheckedContinuation<Void, Never>
}

enum GalleryViewModelTestError: Error {
    case requestedFailure
}

func makeGalleryProgress(week: Int, asOf date: Date) -> PregnancyProgress {
    PregnancyProgress(
        lastPeriodDate: date,
        dueDate: date.addingTimeInterval(120 * 86_400),
        currentWeek: week,
        daysUntilDueDate: 120
    )
}

func makeGalleryCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

@MainActor
func resumeGalleryExportAndWaitForAlert(_ context: GalleryViewModelTestContext) async {
    await withCheckedContinuation { continuation in
        withObservationTracking {
            _ = context.viewModel.activeAlert
        } onChange: {
            continuation.resume()
        }

        Task {
            await context.photoLibraryExporter.resumeNextSave()
        }
    }
}
