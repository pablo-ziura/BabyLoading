import BellyTracking
import CloudBackup
import CoreGraphics
import Foundation
import ImageIO
import PregnancyProgress
import Testing
import UltrasoundGallery
import UniformTypeIdentifiers

struct InitializeBackupUseCaseTests {
    @Test func migrationPreservesHistoricalBytesIdentitiesDatesAndManifestVersion() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let galleryDirectory = root.appendingPathComponent("gallery")
        try FileManager.default.createDirectory(at: galleryDirectory, withIntermediateDirectories: true)
        let original = try jpegFixture()
        let historicalURL = galleryDirectory.appendingPathComponent("historical photo.jpg")
        try original.write(to: historicalURL)
        let creationDate = try historicalURL.resourceValues(forKeys: [.creationDateKey]).creationDate
        let legacyGallery = UltrasoundGalleryStore(containerURL: root)
        let legacyTracking = BellyTrackingStore(containerURL: root)
        try await legacyTracking.updateSettings(BellyTrackingSettings(intervalDays: 28))
        let captureDate = Date(timeIntervalSince1970: 1_770_000_000)
        let trackingEntry = try await legacyTracking.capturePhoto(
            data: original, capturedAt: captureDate, pregnancyWeekAtCapture: 12
        )
        let trackingData = try await legacyTracking.loadImageData(imageFileName: trackingEntry.imageFileName)
        let store = BackupLocalStore(containerURL: root)
        let initialize = InitializeBackupUseCase(
            store: store, legacyProgress: MigrationProgressStore(), legacyGallery: legacyGallery,
            legacyTracking: legacyTracking, calendar: Calendar(identifier: .gregorian), legacyContainerURL: root
        )
        try await initialize.execute()
        try await initialize.execute()
        let snapshot = try await store.snapshot()
        #expect(snapshot.records.count == 2)
        let ultrasound = try #require(snapshot.records.first { $0.remote.origin == .ultrasound })
        #expect(ultrasound.remote.sourceID == "historical photo.jpg")
        #expect(ultrasound.remote.weekNumber == nil)
        #expect(ultrasound.remote.capturedAt == creationDate)
        #expect(try await store.imageData(path: try #require(ultrasound.localImagePath)) == original)
        let tracking = try #require(snapshot.records.first { $0.remote.origin == .bellyTracking })
        #expect(tracking.remote.sourceID == trackingEntry.id.uuidString)
        #expect(tracking.remote.capturedAt == captureDate)
        #expect(tracking.remote.weekNumber == 12)
        #expect(try await store.imageData(path: try #require(tracking.localImagePath)) == trackingData)
        #expect(snapshot.settings.cadenceDays == 28)
        let manifestURL = root.appendingPathComponent("belly-tracking/manifest.json")
        let manifest = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: manifestURL)) as? [String: Any])
        #expect(manifest["schemaVersion"] as? Int == 1)
        #expect(try await legacyGallery.loadPhotos().isEmpty)
        #expect(try await legacyTracking.loadTimeline().isEmpty)
    }

    private func jpegFixture() throws -> Data {
        let context = try #require(CGContext(
            data: nil, width: 48, height: 64, bitsPerComponent: 8, bytesPerRow: 192,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        let image = try #require(context.makeImage())
        let data = NSMutableData()
        let destination = try #require(
            CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil)
        )
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
        return data as Data
    }
}

private actor MigrationProgressStore: PregnancyProgressStoreProtocol {
    func loadLastPeriodDate() -> Date? { Date(timeIntervalSince1970: 1_760_000_000) }
    func updateLastPeriodDate(_ date: Date?) {}
}
