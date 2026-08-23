@testable import BabyLoading
import AppLocalization
import BellyTracking
import Foundation
import PregnancyContent
import PregnancyProgress
import Testing
import UltrasoundGallery

@MainActor
struct BellyTrackingViewModelTests {
    @Test func reloadBellyTrackingStateLoadsTimelineSettingsAndImages() async throws {
        let repository = MockBellyTrackingRepository()
        let entry = BellyTrackingEntry(
            imageFileName: "tracking.jpg",
            capturedAt: .now,
            pregnancyWeekAtCapture: 21
        )
        repository.timeline = [entry]
        repository.imageDataByFileName[entry.imageFileName] = Data([0x99])
        repository.settings = BellyTrackingSettings(intervalDays: 14)
        let viewModel = makeViewModel(repository: repository)

        await viewModel.reloadBellyTrackingState()

        #expect(viewModel.bellyTrackingEntries == [entry])
        #expect(viewModel.bellyTrackingSettings == BellyTrackingSettings(intervalDays: 14))
        #expect(viewModel.lastBellyTrackingEntry == entry)
        #expect(viewModel.lastBellyTrackingImageData == Data([0x99]))
        #expect(viewModel.bellyTrackingState == .loaded)
    }

    @Test func saveBellyTrackingPhotoUpdatesStateAndRepository() async throws {
        let repository = MockBellyTrackingRepository()
        let viewModel = makeViewModel(repository: repository)
        viewModel.pregnancyWeek = 24
        let fakeData = Data([0x0F, 0x0E, 0x0D])

        let didSave = await viewModel.saveBellyTrackingPhoto(fakeData)

        #expect(didSave)
        #expect(repository.captureCallCount == 1)
        #expect(repository.capturedPregnancyWeek == 24)
        #expect(viewModel.bellyTrackingEntries.count == 1)
        #expect(viewModel.lastBellyTrackingEntry?.pregnancyWeekAtCapture == 24)
        #expect(viewModel.lastBellyTrackingImageData == fakeData)
        #expect(viewModel.bellyTrackingState == .loaded)
        #expect(viewModel.ultrasoundPhotos.isEmpty)
    }

    @Test func updateBellyTrackingCadenceUpdatesStateAndStatus() async throws {
        let repository = MockBellyTrackingRepository()
        let calendar = Calendar.current
        let referenceDate = Date.now
        let capturedAt = try #require(
            calendar.date(byAdding: .day, value: -10, to: referenceDate)
        )
        let entry = BellyTrackingEntry(
            imageFileName: "tracking.jpg",
            capturedAt: capturedAt,
            pregnancyWeekAtCapture: 20
        )
        repository.timeline = [entry]
        repository.settings = BellyTrackingSettings(intervalDays: 14)
        let viewModel = makeViewModel(repository: repository)
        await viewModel.reloadBellyTrackingState()
        let initialDueDate = try #require(
            calendar.date(
                byAdding: .day,
                value: 14,
                to: calendar.startOfDay(for: capturedAt)
            )
        )

        #expect(
            viewModel.bellyTrackingStatus(asOf: referenceDate)
                == .upToDate(nextDueDate: initialDueDate)
        )

        await viewModel.updateBellyTrackingCadence(intervalDays: 7)

        #expect(repository.updateSettingsCallCount == 1)
        #expect(repository.settings == BellyTrackingSettings(intervalDays: 7))
        #expect(viewModel.bellyTrackingSettings == BellyTrackingSettings(intervalDays: 7))
        let updatedDueDate = try #require(
            calendar.date(
                byAdding: .day,
                value: 7,
                to: calendar.startOfDay(for: capturedAt)
            )
        )
        #expect(
            viewModel.bellyTrackingStatus(asOf: referenceDate)
                == .pending(nextDueDate: updatedDueDate)
        )
    }

    @Test func deletingTheLastEntryClearsDerivedState() async throws {
        let repository = MockBellyTrackingRepository()
        let entry = BellyTrackingEntry(
            imageFileName: "tracking.jpg",
            capturedAt: .now,
            pregnancyWeekAtCapture: 18
        )
        repository.timeline = [entry]
        repository.imageDataByFileName[entry.imageFileName] = Data([0xAA])
        let viewModel = makeViewModel(repository: repository)
        await viewModel.reloadBellyTrackingState()

        await viewModel.deleteBellyTrackingEntry(id: entry.id)

        #expect(repository.deleteCallCount == 1)
        #expect(repository.deletedIdentifier == entry.id)
        #expect(viewModel.bellyTrackingEntries.isEmpty)
        #expect(viewModel.lastBellyTrackingEntry == nil)
        #expect(viewModel.lastBellyTrackingImageData == nil)
        #expect(viewModel.bellyTrackingStatus(asOf: .now) == .needsInitialCapture)
        #expect(viewModel.bellyTrackingState == .loaded)
    }

    @Test func loadingFailurePreservesTheLastValidState() async throws {
        let repository = MockBellyTrackingRepository()
        let entry = BellyTrackingEntry(
            imageFileName: "tracking.jpg",
            capturedAt: .now,
            pregnancyWeekAtCapture: 18
        )
        repository.timeline = [entry]
        repository.imageDataByFileName[entry.imageFileName] = Data([0xAA])
        repository.settings = BellyTrackingSettings(intervalDays: 14)
        let viewModel = makeViewModel(repository: repository)
        await viewModel.reloadBellyTrackingState()

        repository.loadTimelineError = MockBellyTrackingError.operationFailed
        await viewModel.reloadBellyTrackingState()

        #expect(viewModel.bellyTrackingEntries == [entry])
        #expect(viewModel.lastBellyTrackingImageData == Data([0xAA]))
        #expect(viewModel.bellyTrackingSettings == BellyTrackingSettings(intervalDays: 14))
        #expect(viewModel.bellyTrackingState == .failed(.loadFailed))
    }

    @Test func mutationFailuresPreserveTheLastValidState() async throws {
        let repository = MockBellyTrackingRepository()
        let entry = BellyTrackingEntry(
            imageFileName: "tracking.jpg",
            capturedAt: .now,
            pregnancyWeekAtCapture: 18
        )
        repository.timeline = [entry]
        repository.imageDataByFileName[entry.imageFileName] = Data([0xAA])
        repository.settings = BellyTrackingSettings(intervalDays: 14)
        let viewModel = makeViewModel(repository: repository)
        await viewModel.reloadBellyTrackingState()

        repository.captureError = MockBellyTrackingError.operationFailed
        let didSave = await viewModel.saveBellyTrackingPhoto(Data([0xBB]))
        #expect(!didSave)
        #expect(viewModel.bellyTrackingEntries == [entry])
        #expect(viewModel.bellyTrackingState == .failed(.captureFailed))

        repository.deleteError = MockBellyTrackingError.operationFailed
        await viewModel.deleteBellyTrackingEntry(id: entry.id)
        #expect(viewModel.bellyTrackingEntries == [entry])
        #expect(viewModel.lastBellyTrackingImageData == Data([0xAA]))
        #expect(viewModel.bellyTrackingState == .failed(.deleteFailed))

        repository.updateSettingsError = MockBellyTrackingError.operationFailed
        await viewModel.updateBellyTrackingCadence(intervalDays: 7)
        #expect(viewModel.bellyTrackingSettings == BellyTrackingSettings(intervalDays: 14))
        #expect(viewModel.bellyTrackingState == .failed(.settingsUpdateFailed))
    }

    private func makeViewModel(
        repository: MockBellyTrackingRepository
    ) -> BabyProgressViewModel {
        BabyProgressViewModel(
            loadPregnancyProgressUseCase: MockLoadPregnancyProgressUseCase(),
            updateLastPeriodDateUseCase: MockUpdateLastPeriodDateUseCase(),
            loadPregnancyWeekContentUseCase: MockLoadPregnancyWeekContentUseCase(),
            loadPregnancyTimelineUseCase: MockLoadPregnancyTimelineUseCase(),
            loadUltrasoundPhotosUseCase: MockLoadUltrasoundPhotosUseCase(),
            addUltrasoundPhotoUseCase: MockAddUltrasoundPhotoUseCase(),
            deleteUltrasoundPhotoUseCase: MockDeleteUltrasoundPhotoUseCase(),
            loadBellyTrackingTimelineUseCase: LoadBellyTrackingTimelineUseCase(
                repository: repository
            ),
            loadBellyTrackingImageUseCase: LoadBellyTrackingImageUseCase(
                repository: repository
            ),
            captureBellyTrackingPhotoUseCase: CaptureBellyTrackingPhotoUseCase(
                repository: repository
            ),
            deleteBellyTrackingEntryUseCase: DeleteBellyTrackingEntryUseCase(
                repository: repository
            ),
            loadBellyTrackingSettingsUseCase: LoadBellyTrackingSettingsUseCase(
                repository: repository
            ),
            updateBellyTrackingSettingsUseCase: UpdateBellyTrackingSettingsUseCase(
                repository: repository
            ),
            resolveBellyTrackingStatusUseCase: ResolveBellyTrackingStatusUseCase(
                calendar: .current
            ),
            initialLanguage: .english,
            appVersion: "1.0",
            widgetReloader: MockWidgetReloader()
        )
    }
}
