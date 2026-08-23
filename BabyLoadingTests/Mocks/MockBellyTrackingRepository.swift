import BellyTracking
import Foundation

enum MockBellyTrackingError: Error {
    case operationFailed
}

@MainActor
final class MockBellyTrackingRepository: BellyTrackingRepositoryProtocol {
    var timeline: [BellyTrackingEntry] = []
    var imageDataByFileName: [String: Data] = [:]
    var settings = BellyTrackingSettings.default
    var loadTimelineError: (any Error)?
    var loadImageError: (any Error)?
    var captureError: (any Error)?
    var deleteError: (any Error)?
    var loadSettingsError: (any Error)?
    var updateSettingsError: (any Error)?

    private(set) var loadTimelineCallCount = 0
    private(set) var loadImageCallCount = 0
    private(set) var captureCallCount = 0
    private(set) var deleteCallCount = 0
    private(set) var loadSettingsCallCount = 0
    private(set) var updateSettingsCallCount = 0
    private(set) var capturedPregnancyWeek: Int?
    private(set) var deletedIdentifier: UUID?

    func loadTimeline() async throws -> [BellyTrackingEntry] {
        loadTimelineCallCount += 1
        if let loadTimelineError {
            throw loadTimelineError
        }
        return timeline
    }

    func loadImageData(imageFileName: String) async throws -> Data? {
        loadImageCallCount += 1
        if let loadImageError {
            throw loadImageError
        }
        return imageDataByFileName[imageFileName]
    }

    func capturePhoto(
        data: Data,
        capturedAt: Date,
        pregnancyWeekAtCapture: Int?
    ) async throws -> BellyTrackingEntry {
        captureCallCount += 1
        capturedPregnancyWeek = pregnancyWeekAtCapture
        if let captureError {
            throw captureError
        }

        let entry = BellyTrackingEntry(
            imageFileName: "captured-photo.jpg",
            capturedAt: capturedAt,
            pregnancyWeekAtCapture: pregnancyWeekAtCapture
        )
        timeline.append(entry)
        timeline.sort { $0.capturedAt < $1.capturedAt }
        imageDataByFileName[entry.imageFileName] = data
        return entry
    }

    func deleteEntry(id: UUID) async throws {
        deleteCallCount += 1
        deletedIdentifier = id
        if let deleteError {
            throw deleteError
        }

        guard let index = timeline.firstIndex(where: { $0.id == id }) else {
            return
        }
        let entry = timeline.remove(at: index)
        imageDataByFileName[entry.imageFileName] = nil
    }

    func loadSettings() async throws -> BellyTrackingSettings {
        loadSettingsCallCount += 1
        if let loadSettingsError {
            throw loadSettingsError
        }
        return settings
    }

    func updateSettings(_ settings: BellyTrackingSettings) async throws {
        updateSettingsCallCount += 1
        if let updateSettingsError {
            throw updateSettingsError
        }
        self.settings = settings
    }
}
