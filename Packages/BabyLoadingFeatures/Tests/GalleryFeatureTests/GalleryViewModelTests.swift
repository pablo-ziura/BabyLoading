@testable import GalleryFeature
import BellyTracking
import Foundation
import PregnancyProgress
import Testing
import UltrasoundGallery

@MainActor
struct GalleryViewModelTests {
    @Test func reloadFailuresPreserveEachLastValidSectionIndependently() async {
        let context = GalleryViewModelTestContext()
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let originalPhoto = UltrasoundPhoto(id: "original.jpg", data: Data([0x01]))
        let originalEntry = BellyTrackingEntry(
            imageFileName: "original.heic",
            capturedAt: date,
            pregnancyWeekAtCapture: 20
        )
        context.loadProgressUseCase.result = makeGalleryProgress(week: 20, asOf: date)
        context.loadUltrasoundPhotosUseCase.result = [originalPhoto]
        context.bellyTrackingRepository.timeline = [originalEntry]
        context.bellyTrackingRepository.imageDataByFileName[originalEntry.imageFileName] = Data([0x02])
        context.bellyTrackingRepository.settings = BellyTrackingSettings(intervalDays: 14)
        await context.viewModel.reload(asOf: date)

        context.loadProgressUseCase.error = GalleryViewModelTestError.requestedFailure
        context.loadUltrasoundPhotosUseCase.error = GalleryViewModelTestError.requestedFailure
        context.bellyTrackingRepository.loadTimelineError = GalleryViewModelTestError.requestedFailure
        await context.viewModel.reload(asOf: date)

        #expect(
            context.viewModel.loadingState
                == .failed([.pregnancyProgress, .ultrasoundPhotos, .bellyTracking])
        )
        #expect(context.viewModel.ultrasoundPhotos == [originalPhoto])
        #expect(context.viewModel.bellyTrackingEntries == [originalEntry])
        #expect(context.viewModel.bellyTrackingImageData(for: originalEntry) == Data([0x02]))

        let updatedPhoto = UltrasoundPhoto(id: "updated.jpg", data: Data([0x03]))
        context.loadUltrasoundPhotosUseCase.error = nil
        context.loadUltrasoundPhotosUseCase.result = [updatedPhoto]
        await context.viewModel.reload(asOf: date)

        #expect(context.viewModel.loadingState == .failed([.pregnancyProgress, .bellyTracking]))
        #expect(context.viewModel.ultrasoundPhotos == [updatedPhoto])
        #expect(context.viewModel.bellyTrackingEntries == [originalEntry])

        let updatedEntry = BellyTrackingEntry(
            imageFileName: "updated.heic",
            capturedAt: date.addingTimeInterval(86_400),
            pregnancyWeekAtCapture: 21
        )
        context.bellyTrackingRepository.loadTimelineError = nil
        context.bellyTrackingRepository.timeline = [updatedEntry]
        context.bellyTrackingRepository.imageDataByFileName[updatedEntry.imageFileName] = Data([0x04])
        await context.viewModel.reload(asOf: date)

        #expect(context.viewModel.loadingState == .failed([.pregnancyProgress]))
        #expect(context.viewModel.ultrasoundPhotos == [updatedPhoto])
        #expect(context.viewModel.bellyTrackingEntries == [updatedEntry])
        #expect(context.viewModel.bellyTrackingImageData(for: updatedEntry) == Data([0x04]))
    }

    @Test func ultrasoundAddAndDeleteUpdateOnlyPersistedResults() async throws {
        let context = GalleryViewModelTestContext()
        let firstData = Data([0x01])
        let replacementData = Data([0x02])

        await context.viewModel.addUltrasoundPhoto(firstData)
        await context.viewModel.addUltrasoundPhoto(replacementData)

        let photo = try #require(context.viewModel.ultrasoundPhotos.first)
        #expect(context.addUltrasoundPhotoUseCase.executeCallCount == 2)
        #expect(context.addUltrasoundPhotoUseCase.addedData == replacementData)
        #expect(context.viewModel.ultrasoundPhotos == [photo])
        #expect(photo.data == replacementData)
        #expect(context.viewModel.operationState == .idle)

        await context.viewModel.deleteUltrasoundPhoto(id: photo.id)

        #expect(context.deleteUltrasoundPhotoUseCase.executeCallCount == 1)
        #expect(context.deleteUltrasoundPhotoUseCase.deletedIdentifier == photo.id)
        #expect(context.viewModel.ultrasoundPhotos.isEmpty)
        #expect(context.viewModel.operationState == .idle)
    }

    @Test func ultrasoundMutationFailuresPreserveLastValidPhotos() async {
        let context = GalleryViewModelTestContext()
        let photo = UltrasoundPhoto(id: "existing.jpg", data: Data([0x01]))
        context.loadUltrasoundPhotosUseCase.result = [photo]
        await context.viewModel.reload()

        context.addUltrasoundPhotoUseCase.error = GalleryViewModelTestError.requestedFailure
        await context.viewModel.addUltrasoundPhoto(Data([0x02]))

        #expect(context.viewModel.ultrasoundPhotos == [photo])
        #expect(context.viewModel.operationState == .failed(.importUltrasoundPhoto))

        context.deleteUltrasoundPhotoUseCase.error = GalleryViewModelTestError.requestedFailure
        await context.viewModel.deleteUltrasoundPhoto(id: photo.id)

        #expect(context.viewModel.ultrasoundPhotos == [photo])
        #expect(context.viewModel.operationState == .failed(.deleteUltrasoundPhoto))
    }

    @Test func captureUsesLoadedPregnancyWeekAndExportsImage() async {
        let context = GalleryViewModelTestContext()
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let imageData = Data([0x01, 0x02, 0x03])
        context.loadProgressUseCase.result = makeGalleryProgress(week: 24, asOf: date)
        await context.viewModel.reload(asOf: date)

        let didSave = await context.viewModel.saveCapturedBellyTrackingPhoto(imageData, capturedAt: date)
        await context.photoLibraryExporter.waitForSaveCount(1)
        let exportSnapshot = await context.photoLibraryExporter.snapshot()

        #expect(didSave)
        #expect(context.bellyTrackingRepository.captureCallCount == 1)
        #expect(context.bellyTrackingRepository.capturedPregnancyWeek == 24)
        #expect(context.viewModel.lastBellyTrackingEntry?.pregnancyWeekAtCapture == 24)
        #expect(context.viewModel.lastBellyTrackingImageData == imageData)
        #expect(exportSnapshot.savedData == [imageData])
        #expect(context.viewModel.operationState == .idle)
    }

    @Test func failedProgressReloadDoesNotReuseStaleWeekForCapture() async {
        let context = GalleryViewModelTestContext()
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        context.loadProgressUseCase.result = makeGalleryProgress(week: 24, asOf: date)
        await context.viewModel.reload(asOf: date)

        context.loadProgressUseCase.error = GalleryViewModelTestError.requestedFailure
        await context.viewModel.reload(asOf: date)
        let didSave = await context.viewModel.saveCapturedBellyTrackingPhoto(Data([0x01]))

        #expect(didSave)
        #expect(context.bellyTrackingRepository.capturedPregnancyWeek == nil)
    }

    @Test func persistedCaptureRemainsSuccessfulWhenImageReloadFails() async {
        let context = GalleryViewModelTestContext()
        let originalData = Data([0x01, 0x02])
        context.bellyTrackingRepository.loadImageError = GalleryViewModelTestError.requestedFailure

        let didSave = await context.viewModel.saveCapturedBellyTrackingPhoto(originalData)
        await context.photoLibraryExporter.waitForSaveCount(1)
        let exportSnapshot = await context.photoLibraryExporter.snapshot()

        #expect(didSave)
        #expect(context.bellyTrackingRepository.captureCallCount == 1)
        #expect(context.viewModel.bellyTrackingEntries.count == 1)
        #expect(context.viewModel.lastBellyTrackingImageData == nil)
        #expect(exportSnapshot.savedData == [originalData])
        #expect(context.viewModel.operationState == .failed(.loadBellyTrackingImage))
    }

    @Test func captureReturnsWhilePhotoLibraryExportRemainsSuspended() async {
        let context = GalleryViewModelTestContext()
        let data = Data([0x01])
        await context.photoLibraryExporter.suspendNextSave()

        let didSave = await context.viewModel.saveCapturedBellyTrackingPhoto(data)
        await context.photoLibraryExporter.waitForSaveCount(1)
        let exportSnapshot = await context.photoLibraryExporter.snapshot()

        #expect(didSave)
        #expect(context.viewModel.bellyTrackingEntries.count == 1)
        #expect(exportSnapshot.savedData == [data])

        await context.photoLibraryExporter.resumeNextSave()
    }

    @Test func photoLibraryExportResultsMapToAlerts() async {
        let context = GalleryViewModelTestContext()
        let data = Data([0x01])

        await context.photoLibraryExporter.setResult(.permissionDenied)
        await context.photoLibraryExporter.suspendNextSave()
        #expect(await context.viewModel.saveCapturedBellyTrackingPhoto(data))
        await context.photoLibraryExporter.waitForSaveCount(1)
        await resumeGalleryExportAndWaitForAlert(context)
        #expect(context.viewModel.activeAlert == .photoLibraryPermissionDenied)

        context.viewModel.clearActiveAlert()
        await context.photoLibraryExporter.setResult(.failed)
        await context.photoLibraryExporter.suspendNextSave()
        #expect(await context.viewModel.saveCapturedBellyTrackingPhoto(data))
        await context.photoLibraryExporter.waitForSaveCount(2)
        await resumeGalleryExportAndWaitForAlert(context)
        #expect(context.viewModel.activeAlert == .photoLibraryExportFailed)
    }

    @Test func trackingDeletionFailurePreservesStateBeforeSuccessfulDeletion() async {
        let context = GalleryViewModelTestContext()
        let entry = BellyTrackingEntry(
            imageFileName: "capture.heic",
            capturedAt: Date(timeIntervalSince1970: 1_700_000_000),
            pregnancyWeekAtCapture: 20
        )
        context.bellyTrackingRepository.timeline = [entry]
        context.bellyTrackingRepository.imageDataByFileName[entry.imageFileName] = Data([0x01])
        await context.viewModel.reload()

        context.viewModel.requestBellyTrackingDeletion(entry)
        #expect(context.viewModel.activeAlert == .confirmBellyTrackingDeletion(entry))
        context.viewModel.clearActiveAlert()

        context.bellyTrackingRepository.deleteError = GalleryViewModelTestError.requestedFailure
        await context.viewModel.deleteBellyTrackingEntry(id: entry.id)

        #expect(context.viewModel.bellyTrackingEntries == [entry])
        #expect(context.viewModel.bellyTrackingImageData(for: entry) == Data([0x01]))
        #expect(context.viewModel.operationState == .failed(.deleteBellyTrackingPhoto))

        context.bellyTrackingRepository.deleteError = nil
        await context.viewModel.deleteBellyTrackingEntry(id: entry.id)

        #expect(context.bellyTrackingRepository.deletedIdentifier == entry.id)
        #expect(context.viewModel.bellyTrackingEntries.isEmpty)
        #expect(context.viewModel.bellyTrackingImageData(for: entry) == nil)
        #expect(context.viewModel.operationState == .idle)
    }

    @Test func cadenceUpdatesStatusAndFailurePreservesCurrentSettings() async throws {
        let calendar = makeGalleryCalendar()
        let context = GalleryViewModelTestContext(calendar: calendar)
        let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)
        let capturedAt = try #require(calendar.date(byAdding: .day, value: -10, to: referenceDate))
        let entry = BellyTrackingEntry(
            imageFileName: "capture.heic",
            capturedAt: capturedAt,
            pregnancyWeekAtCapture: 20
        )
        context.bellyTrackingRepository.timeline = [entry]
        context.bellyTrackingRepository.settings = BellyTrackingSettings(intervalDays: 14)
        await context.viewModel.reload(asOf: referenceDate)
        let captureDay = calendar.startOfDay(for: capturedAt)
        let initialDueDate = try #require(calendar.date(byAdding: .day, value: 14, to: captureDay))

        #expect(context.viewModel.bellyTrackingStatus(asOf: referenceDate) == .upToDate(nextDueDate: initialDueDate))

        await context.viewModel.updateBellyTrackingCadence(intervalDays: 7)
        let updatedDueDate = try #require(calendar.date(byAdding: .day, value: 7, to: captureDay))

        #expect(context.bellyTrackingRepository.settings == BellyTrackingSettings(intervalDays: 7))
        #expect(context.viewModel.bellyTrackingSettings == BellyTrackingSettings(intervalDays: 7))
        #expect(context.viewModel.bellyTrackingStatus(asOf: referenceDate) == .pending(nextDueDate: updatedDueDate))
        #expect(context.viewModel.operationState == .idle)

        context.bellyTrackingRepository.updateSettingsError = GalleryViewModelTestError.requestedFailure
        await context.viewModel.updateBellyTrackingCadence(intervalDays: 28)

        #expect(context.viewModel.bellyTrackingSettings == BellyTrackingSettings(intervalDays: 7))
        #expect(context.viewModel.operationState == .failed(.updateTrackingCadence))
    }
}
