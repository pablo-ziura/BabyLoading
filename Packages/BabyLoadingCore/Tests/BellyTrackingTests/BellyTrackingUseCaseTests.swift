@testable import BellyTracking
import Foundation
import Testing

struct BellyTrackingUseCaseTests {
    @Test func operationSpecificUseCasesCoverTheTrackingLifecycle() async throws {
        let containerURL = try BellyTrackingTestSupport.makeContainer()
        defer { BellyTrackingTestSupport.removeContainer(containerURL) }
        let repository = BellyTrackingRepository(
            store: BellyTrackingStore(containerURL: containerURL)
        )
        let loadTimeline = LoadBellyTrackingTimelineUseCase(repository: repository)
        let loadImage = LoadBellyTrackingImageUseCase(repository: repository)
        let capturePhoto = CaptureBellyTrackingPhotoUseCase(repository: repository)
        let deleteEntry = DeleteBellyTrackingEntryUseCase(repository: repository)
        let loadSettings = LoadBellyTrackingSettingsUseCase(repository: repository)
        let updateSettings = UpdateBellyTrackingSettingsUseCase(repository: repository)
        let resolveStatus = ResolveBellyTrackingStatusUseCase(calendar: utcCalendar)
        let capturedAt = try BellyTrackingTestSupport.date("2026-08-13T08:00:00Z")
        let cadenceDate = try BellyTrackingTestSupport.date("2026-08-27T08:00:00Z")
        let expectedDueDate = try BellyTrackingTestSupport.date("2026-08-27T00:00:00Z")
        let jpegData = try BellyTrackingTestSupport.makeJPEGData()

        #expect(
            resolveStatus.execute(
                settings: .default,
                lastCapture: nil,
                asOf: capturedAt
            ) == .needsInitialCapture
        )
        try await updateSettings.execute(BellyTrackingSettings(intervalDays: 14))
        #expect(try await loadSettings.execute().intervalDays == 14)

        let entry = try await capturePhoto.execute(
            data: jpegData,
            capturedAt: capturedAt,
            pregnancyWeekAtCapture: 22
        )

        #expect(try await loadTimeline.execute() == [entry])
        #expect(try await loadImage.execute(imageFileName: entry.imageFileName) != nil)
        #expect(
            resolveStatus.execute(
                settings: try await loadSettings.execute(),
                lastCapture: entry.capturedAt,
                asOf: cadenceDate
            )
                == .upToDate(nextDueDate: expectedDueDate)
        )

        try await deleteEntry.execute(id: entry.id)
        #expect(try await loadTimeline.execute().isEmpty)
        #expect(try await loadImage.execute(imageFileName: entry.imageFileName) == nil)
    }

    @Test func captureUseCasePropagatesTypedStorageErrors() async throws {
        let containerURL = try BellyTrackingTestSupport.makeContainer()
        defer { BellyTrackingTestSupport.removeContainer(containerURL) }
        let repository = BellyTrackingRepository(
            store: BellyTrackingStore(containerURL: containerURL)
        )
        let capturePhoto = CaptureBellyTrackingPhotoUseCase(repository: repository)

        do {
            _ = try await capturePhoto.execute(
                data: Data("invalid".utf8),
                capturedAt: .now,
                pregnancyWeekAtCapture: nil
            )
            Issue.record("Storage errors must reach the caller")
        } catch let error as BellyTrackingStoreError {
            #expect(error == .unsupportedImageFormat)
        }
    }

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
        return calendar
    }
}
