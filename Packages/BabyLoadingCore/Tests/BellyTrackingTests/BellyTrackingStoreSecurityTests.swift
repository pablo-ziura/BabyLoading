@testable import BellyTracking
import Foundation
import Testing

struct BellyTrackingStoreSecurityTests {
    @Test func rejectsDuplicateManifestIdentifiersAndImageFileNames() async throws {
        let containerURL = try BellyTrackingTestSupport.makeContainer()
        defer { BellyTrackingTestSupport.removeContainer(containerURL) }
        let duplicateIdentifier = UUID()
        let firstEntry = BellyTrackingEntry(
            id: duplicateIdentifier,
            imageFileName: "first.jpg",
            capturedAt: .now,
            pregnancyWeekAtCapture: nil
        )
        let secondEntry = BellyTrackingEntry(
            id: duplicateIdentifier,
            imageFileName: "second.jpg",
            capturedAt: .now,
            pregnancyWeekAtCapture: nil
        )
        try writeManifest(
            BellyTrackingManifest(
                schemaVersion: 1,
                settings: .default,
                entries: [firstEntry, secondEntry]
            ),
            to: containerURL
        )
        let store = BellyTrackingStore(containerURL: containerURL)

        do {
            _ = try await store.loadTimeline()
            Issue.record("Duplicate entry identifiers must throw")
        } catch let error as BellyTrackingStoreError {
            #expect(error == .duplicateEntryIdentifier(duplicateIdentifier))
        }

        let duplicateFileName = "duplicate.jpg"
        try writeManifest(
            BellyTrackingManifest(
                schemaVersion: 1,
                settings: .default,
                entries: [
                    BellyTrackingEntry(
                        imageFileName: duplicateFileName,
                        capturedAt: .now,
                        pregnancyWeekAtCapture: nil
                    ),
                    BellyTrackingEntry(
                        imageFileName: duplicateFileName,
                        capturedAt: .now,
                        pregnancyWeekAtCapture: nil
                    )
                ]
            ),
            to: containerURL
        )

        do {
            _ = try await store.loadTimeline()
            Issue.record("Duplicate image file names must throw")
        } catch let error as BellyTrackingStoreError {
            #expect(error == .duplicateImageFileName(duplicateFileName))
        }
    }

    @Test func rejectsTrackingDirectorySymlinksWithoutTouchingTheirDestination() async throws {
        let containerURL = try BellyTrackingTestSupport.makeContainer()
        let externalURL = try BellyTrackingTestSupport.makeContainer()
        defer {
            BellyTrackingTestSupport.removeContainer(containerURL)
            BellyTrackingTestSupport.removeContainer(externalURL)
        }
        let sentinelURL = externalURL.appendingPathComponent("sentinel.txt")
        let sentinelData = Data("outside".utf8)
        try sentinelData.write(to: sentinelURL)
        try FileManager.default.createSymbolicLink(
            at: containerURL.appendingPathComponent(BellyTrackingStore.directoryName),
            withDestinationURL: externalURL
        )
        let store = BellyTrackingStore(containerURL: containerURL)

        do {
            _ = try await store.loadTimeline()
            Issue.record("Tracking directory symlinks must throw")
        } catch let error as BellyTrackingStoreError {
            #expect(error == .invalidTrackingDirectory)
        }

        #expect(try Data(contentsOf: sentinelURL) == sentinelData)
        #expect(
            try FileManager.default.contentsOfDirectory(atPath: externalURL.path)
                == [sentinelURL.lastPathComponent]
        )
    }

    @Test func rejectsManifestSymlinksWithoutMutatingTheirDestination() async throws {
        let containerURL = try BellyTrackingTestSupport.makeContainer()
        let externalURL = try BellyTrackingTestSupport.makeContainer()
        defer {
            BellyTrackingTestSupport.removeContainer(containerURL)
            BellyTrackingTestSupport.removeContainer(externalURL)
        }
        let trackingURL = containerURL.appendingPathComponent(
            BellyTrackingStore.directoryName,
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: trackingURL,
            withIntermediateDirectories: true
        )
        let externalManifestURL = externalURL.appendingPathComponent("external.json")
        let sentinelData = Data("outside".utf8)
        try sentinelData.write(to: externalManifestURL)
        try FileManager.default.createSymbolicLink(
            at: trackingURL.appendingPathComponent(BellyTrackingStore.manifestFileName),
            withDestinationURL: externalManifestURL
        )
        let store = BellyTrackingStore(containerURL: containerURL)

        do {
            try await store.updateSettings(BellyTrackingSettings(intervalDays: 14))
            Issue.record("Manifest symlinks must throw")
        } catch let error as BellyTrackingStoreError {
            #expect(error == .invalidManifestFile)
        }

        #expect(try Data(contentsOf: externalManifestURL) == sentinelData)
    }

    @Test func rejectsImageSymlinksBeforeCommittingDeletion() async throws {
        let containerURL = try BellyTrackingTestSupport.makeContainer()
        let externalURL = try BellyTrackingTestSupport.makeContainer()
        defer {
            BellyTrackingTestSupport.removeContainer(containerURL)
            BellyTrackingTestSupport.removeContainer(externalURL)
        }
        let entry = BellyTrackingEntry(
            imageFileName: "linked.jpg",
            capturedAt: try BellyTrackingTestSupport.date("2026-03-01T09:30:00Z"),
            pregnancyWeekAtCapture: 24
        )
        try writeManifest(
            BellyTrackingManifest(
                schemaVersion: 1,
                settings: .default,
                entries: [entry]
            ),
            to: containerURL
        )
        let externalImageURL = externalURL.appendingPathComponent("outside.jpg")
        let sentinelData = Data("outside".utf8)
        try sentinelData.write(to: externalImageURL)
        let trackingURL = containerURL.appendingPathComponent(
            BellyTrackingStore.directoryName,
            isDirectory: true
        )
        try FileManager.default.createSymbolicLink(
            at: trackingURL.appendingPathComponent(entry.imageFileName),
            withDestinationURL: externalImageURL
        )
        let store = BellyTrackingStore(containerURL: containerURL)

        do {
            try await store.deleteEntry(id: entry.id)
            Issue.record("Image symlinks must throw")
        } catch let error as BellyTrackingStoreError {
            #expect(error == .invalidImageFileName(entry.imageFileName))
        }

        #expect(try await store.loadTimeline() == [entry])
        #expect(try Data(contentsOf: externalImageURL) == sentinelData)
    }

    private func writeManifest(
        _ manifest: BellyTrackingManifest,
        to containerURL: URL
    ) throws {
        let trackingURL = containerURL.appendingPathComponent(
            BellyTrackingStore.directoryName,
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: trackingURL,
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(manifest).write(
            to: trackingURL.appendingPathComponent(BellyTrackingStore.manifestFileName),
            options: .atomic
        )
    }
}
