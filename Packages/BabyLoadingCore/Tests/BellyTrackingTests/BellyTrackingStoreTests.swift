@testable import BellyTracking
import Foundation
import ImageIO
import Testing

struct BellyTrackingStoreTests {
    @Test func persistsTheExactManifestV1ContractInItsDedicatedDirectory() async throws {
        let containerURL = try BellyTrackingTestSupport.makeContainer()
        defer { BellyTrackingTestSupport.removeContainer(containerURL) }
        let store = BellyTrackingStore(containerURL: containerURL)
        let capturedAt = try BellyTrackingTestSupport.date("2026-03-01T09:30:00Z")
        let jpegData = try BellyTrackingTestSupport.makeJPEGData(
            width: 400,
            height: 300
        )

        try await store.updateSettings(BellyTrackingSettings(intervalDays: 14))
        let entry = try await store.capturePhoto(
            data: jpegData,
            capturedAt: capturedAt,
            pregnancyWeekAtCapture: 22
        )

        let trackingURL = containerURL.appendingPathComponent(
            BellyTrackingStore.directoryName,
            isDirectory: true
        )
        let manifestURL = trackingURL.appendingPathComponent(
            BellyTrackingStore.manifestFileName
        )
        let manifestObject = try #require(
            JSONSerialization.jsonObject(with: Data(contentsOf: manifestURL))
                as? [String: Any]
        )
        let settingsObject = try #require(
            manifestObject["settings"] as? [String: Any]
        )
        let entries = try #require(manifestObject["entries"] as? [[String: Any]])
        let persistedEntry = try #require(entries.first)

        #expect(BellyTrackingStore.directoryName == "belly-tracking")
        #expect(BellyTrackingStore.manifestFileName == "manifest.json")
        #expect(BellyTrackingManifest.currentSchemaVersion == 1)
        #expect(Set(manifestObject.keys) == ["entries", "schemaVersion", "settings"])
        #expect(manifestObject["schemaVersion"] as? Int == 1)
        #expect(settingsObject["intervalDays"] as? Int == 14)
        #expect(
            Set(persistedEntry.keys) == [
                "capturedAt",
                "id",
                "imageFileName",
                "pregnancyWeekAtCapture"
            ]
        )
        #expect(persistedEntry["id"] as? String == entry.id.uuidString)
        #expect(persistedEntry["imageFileName"] as? String == entry.imageFileName)
        #expect(persistedEntry["capturedAt"] as? String == "2026-03-01T09:30:00Z")
        #expect(persistedEntry["pregnancyWeekAtCapture"] as? Int == 22)
        #expect(entry.imageFileName.hasSuffix(".jpg"))
        #expect(
            Set(try FileManager.default.contentsOfDirectory(atPath: trackingURL.path))
                == [BellyTrackingStore.manifestFileName, entry.imageFileName]
        )
        #expect(!FileManager.default.fileExists(
            atPath: containerURL.appendingPathComponent("gallery").path
        ))

        let reloadedStore = BellyTrackingStore(containerURL: containerURL)
        #expect(try await reloadedStore.loadTimeline() == [entry])
        #expect(try await reloadedStore.loadSettings().intervalDays == 14)
        let storedImageData = try #require(
            try await reloadedStore.loadImageData(imageFileName: entry.imageFileName)
        )
        let storedImageProperties = try BellyTrackingTestSupport.imageProperties(
            for: storedImageData
        )
        #expect(storedImageProperties[kCGImagePropertyPixelWidth] as? Int == 168)
        #expect(storedImageProperties[kCGImagePropertyPixelHeight] as? Int == 300)
    }

    @Test func loadsHistoricalJPEGAndHEICCapturesWithoutReencoding() async throws {
        let containerURL = try BellyTrackingTestSupport.makeContainer()
        defer { BellyTrackingTestSupport.removeContainer(containerURL) }
        let trackingURL = containerURL.appendingPathComponent(
            BellyTrackingStore.directoryName,
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: trackingURL,
            withIntermediateDirectories: true
        )
        let jpegData = try BellyTrackingTestSupport.makeJPEGData()
        let heicData = try BellyTrackingTestSupport.makeHEICData()
        try jpegData.write(to: trackingURL.appendingPathComponent("legacy-capture.jpg"))
        try heicData.write(to: trackingURL.appendingPathComponent("native-capture.heic"))
        try historicalManifestData.write(
            to: trackingURL.appendingPathComponent(BellyTrackingStore.manifestFileName)
        )
        let store = BellyTrackingStore(containerURL: containerURL)

        let timeline = try await store.loadTimeline()

        #expect(
            timeline.map(\.imageFileName)
                == ["legacy-capture.jpg", "native-capture.heic"]
        )
        #expect(
            try await store.loadImageData(imageFileName: "legacy-capture.jpg")
                == jpegData
        )
        #expect(
            try await store.loadImageData(imageFileName: "native-capture.heic")
                == heicData
        )
    }

    @Test func storesTimelineEntriesInChronologicalOrder() async throws {
        let containerURL = try BellyTrackingTestSupport.makeContainer()
        defer { BellyTrackingTestSupport.removeContainer(containerURL) }
        let store = BellyTrackingStore(containerURL: containerURL)
        let jpegData = try BellyTrackingTestSupport.makeJPEGData()
        let firstDate = try BellyTrackingTestSupport.date("2026-02-10T08:00:00Z")
        let secondDate = try BellyTrackingTestSupport.date("2026-03-10T08:00:00Z")

        _ = try await store.capturePhoto(
            data: jpegData,
            capturedAt: secondDate,
            pregnancyWeekAtCapture: 24
        )
        _ = try await store.capturePhoto(
            data: jpegData,
            capturedAt: firstDate,
            pregnancyWeekAtCapture: 20
        )

        #expect(try await store.loadTimeline().map(\.capturedAt) == [firstDate, secondDate])
    }

    @Test func deletionRemovesTheManifestEntryAndItsImage() async throws {
        let containerURL = try BellyTrackingTestSupport.makeContainer()
        defer { BellyTrackingTestSupport.removeContainer(containerURL) }
        let store = BellyTrackingStore(containerURL: containerURL)
        let entry = try await store.capturePhoto(
            data: BellyTrackingTestSupport.makeJPEGData(),
            capturedAt: .now,
            pregnancyWeekAtCapture: nil
        )

        try await store.deleteEntry(id: entry.id)

        #expect(try await store.loadTimeline().isEmpty)
        #expect(try await store.loadImageData(imageFileName: entry.imageFileName) == nil)
    }

    @Test func newJPEGAndHEICCapturesAreStoredWithMaterializedPortraitGeometry() async throws {
        let containerURL = try BellyTrackingTestSupport.makeContainer()
        defer { BellyTrackingTestSupport.removeContainer(containerURL) }
        let store = BellyTrackingStore(containerURL: containerURL)
        let jpegEntry = try await store.capturePhoto(
            data: BellyTrackingTestSupport.makeOrientedJPEGData(exifOrientation: 6),
            capturedAt: try BellyTrackingTestSupport.date("2026-03-01T09:30:00Z"),
            pregnancyWeekAtCapture: 22
        )
        let heicEntry = try await store.capturePhoto(
            data: BellyTrackingTestSupport.makeOrientedHEICData(exifOrientation: 6),
            capturedAt: try BellyTrackingTestSupport.date("2026-03-08T09:30:00Z"),
            pregnancyWeekAtCapture: 23
        )

        let jpegData = try #require(
            try await store.loadImageData(imageFileName: jpegEntry.imageFileName)
        )
        let heicData = try #require(
            try await store.loadImageData(imageFileName: heicEntry.imageFileName)
        )
        let jpegProperties = try BellyTrackingTestSupport.imageProperties(for: jpegData)
        let heicProperties = try BellyTrackingTestSupport.imageProperties(for: heicData)

        #expect(jpegEntry.imageFileName.hasSuffix(".jpg"))
        #expect(heicEntry.imageFileName.hasSuffix(".heic"))
        #expect(jpegProperties[kCGImagePropertyPixelWidth] as? Int == 225)
        #expect(jpegProperties[kCGImagePropertyPixelHeight] as? Int == 400)
        #expect((jpegProperties[kCGImagePropertyOrientation] as? Int ?? 1) == 1)
        #expect(heicProperties[kCGImagePropertyPixelWidth] as? Int == 225)
        #expect(heicProperties[kCGImagePropertyPixelHeight] as? Int == 400)
        #expect((heicProperties[kCGImagePropertyOrientation] as? Int ?? 1) == 1)
    }

    @Test func normalizesCaptureDatesToTheManifestPrecision() async throws {
        let containerURL = try BellyTrackingTestSupport.makeContainer()
        defer { BellyTrackingTestSupport.removeContainer(containerURL) }
        let store = BellyTrackingStore(containerURL: containerURL)
        let capturedAt = Date(timeIntervalSince1970: 1_772_361_000.875)
        let expectedDate = Date(timeIntervalSince1970: 1_772_361_000)

        let entry = try await store.capturePhoto(
            data: BellyTrackingTestSupport.makeJPEGData(),
            capturedAt: capturedAt,
            pregnancyWeekAtCapture: nil
        )

        #expect(entry.capturedAt == expectedDate)
        #expect(try await store.loadTimeline() == [entry])
    }

    @Test func rejectsUnsupportedManifestSchema() async throws {
        let containerURL = try BellyTrackingTestSupport.makeContainer()
        defer { BellyTrackingTestSupport.removeContainer(containerURL) }
        try writeManifest(
            BellyTrackingManifest(schemaVersion: 2, settings: .default, entries: []),
            to: containerURL
        )
        let store = BellyTrackingStore(containerURL: containerURL)

        do {
            _ = try await store.loadTimeline()
            Issue.record("Unsupported manifests must throw")
        } catch let error as BellyTrackingStoreError {
            #expect(error == .unsupportedManifestSchema(2))
        }
    }

    @Test func rejectsUnsafeImageFileNamesFromCallersAndManifestData() async throws {
        let containerURL = try BellyTrackingTestSupport.makeContainer()
        defer { BellyTrackingTestSupport.removeContainer(containerURL) }
        let store = BellyTrackingStore(containerURL: containerURL)

        do {
            _ = try await store.loadImageData(imageFileName: "../gallery/photo.jpg")
            Issue.record("Path traversal must throw")
        } catch let error as BellyTrackingStoreError {
            #expect(error == .invalidImageFileName("../gallery/photo.jpg"))
        }

        let entry = BellyTrackingEntry(
            imageFileName: "..",
            capturedAt: .now,
            pregnancyWeekAtCapture: nil
        )
        try writeManifest(
            BellyTrackingManifest(schemaVersion: 1, settings: .default, entries: [entry]),
            to: containerURL
        )

        do {
            _ = try await store.loadTimeline()
            Issue.record("Unsafe manifest image names must throw")
        } catch let error as BellyTrackingStoreError {
            #expect(error == .invalidImageFileName(".."))
        }
    }

    @Test func rejectsReservedAndUnsupportedImageFileNames() async throws {
        let containerURL = try BellyTrackingTestSupport.makeContainer()
        defer { BellyTrackingTestSupport.removeContainer(containerURL) }
        let store = BellyTrackingStore(containerURL: containerURL)
        let invalidFileNames = [
            BellyTrackingStore.manifestFileName,
            "manifest.json.backup",
            "capture.png",
            "capture",
            "capture.jpg/child"
        ]

        for fileName in invalidFileNames {
            do {
                _ = try await store.loadImageData(imageFileName: fileName)
                Issue.record("Invalid image file names must throw: \(fileName)")
            } catch let error as BellyTrackingStoreError {
                #expect(error == .invalidImageFileName(fileName))
            }
        }
    }

    @Test func normalizesUnsupportedCadenceFromHistoricalManifest() async throws {
        let containerURL = try BellyTrackingTestSupport.makeContainer()
        defer { BellyTrackingTestSupport.removeContainer(containerURL) }
        let trackingURL = containerURL.appendingPathComponent(
            BellyTrackingStore.directoryName,
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: trackingURL,
            withIntermediateDirectories: true
        )
        let manifestData = Data(
            """
            {
              "entries" : [],
              "schemaVersion" : 1,
              "settings" : { "intervalDays" : 10 }
            }
            """.utf8
        )
        try manifestData.write(
            to: trackingURL.appendingPathComponent(BellyTrackingStore.manifestFileName)
        )
        let store = BellyTrackingStore(containerURL: containerURL)

        #expect(
            try await store.loadSettings().intervalDays
                == BellyTrackingSettings.defaultIntervalDays
        )
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

    private var historicalManifestData: Data {
        Data(
            """
            {
              "entries" : [
                {
                  "capturedAt" : "2026-03-10T08:00:00Z",
                  "id" : "970FECC3-1A8D-4E18-A5E6-C987E57C8690",
                  "imageFileName" : "native-capture.heic",
                  "pregnancyWeekAtCapture" : 24
                },
                {
                  "capturedAt" : "2026-02-10T08:00:00Z",
                  "id" : "0E9C6D3B-B04A-419B-8165-3DA71354291F",
                  "imageFileName" : "legacy-capture.jpg",
                  "pregnancyWeekAtCapture" : 20
                }
              ],
              "schemaVersion" : 1,
              "settings" : { "intervalDays" : 7 }
            }
            """.utf8
        )
    }
}
