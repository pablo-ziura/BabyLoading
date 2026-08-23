@testable import BabyLoading
import AppPreferences
import CoreImage
import Foundation
import Testing
import UIKit

struct MediaStorageContractTests {
    @Test func ultrasoundGalleryUsesItsDedicatedDirectoryAndFileNameIdentity() throws {
        let context = try makeContext()
        defer { cleanup(context) }
        let imageData = makeJPEGData(color: .systemBlue)

        context.dataSource.addUltrasoundPhoto(data: imageData)

        let galleryURL = context.containerURL.appendingPathComponent("gallery", isDirectory: true)
        let galleryFiles = try FileManager.default.contentsOfDirectory(
            at: galleryURL,
            includingPropertiesForKeys: nil
        )
        let storedFileURL = try #require(galleryFiles.onlyElement)
        let storedPhoto = try #require(context.dataSource.fetchUltrasoundPhotos().onlyElement)

        #expect(storedFileURL.pathExtension == "jpg")
        #expect(storedPhoto.id == storedFileURL.lastPathComponent)
        #expect(storedPhoto.data == imageData)
        #expect(
            try FileManager.default.contentsOfDirectory(
                at: context.containerURL,
                includingPropertiesForKeys: nil
            ).map(\.lastPathComponent) == ["gallery"]
        )

        let reloadedDataSource = makeDataSource(context)
        #expect(reloadedDataSource.fetchUltrasoundPhotos().onlyElement?.id == storedPhoto.id)
    }

    @Test func bellyTrackingPersistsManifestSchemaVersionOneInItsDedicatedDirectory() throws {
        let context = try makeContext()
        defer { cleanup(context) }
        let capturedAt = try #require(ISO8601DateFormatter().date(from: "2026-03-01T09:30:00Z"))
        context.dataSource.saveBellyTrackingSettings(BellyTrackingSettings(intervalDays: 14))

        let entry = try #require(
            context.dataSource.saveBellyTrackingPhoto(
                data: makeJPEGData(color: .systemPink),
                capturedAt: capturedAt,
                pregnancyWeekAtCapture: 22
            )
        )

        let trackingURL = context.containerURL.appendingPathComponent("belly-tracking", isDirectory: true)
        let manifestURL = trackingURL.appendingPathComponent("manifest.json")
        let manifestData = try Data(contentsOf: manifestURL)
        let manifest = try #require(
            JSONSerialization.jsonObject(with: manifestData) as? [String: Any]
        )
        let settings = try #require(manifest["settings"] as? [String: Any])
        let entries = try #require(manifest["entries"] as? [[String: Any]])
        let persistedEntry = try #require(entries.onlyElement)

        #expect(Set(manifest.keys) == ["entries", "schemaVersion", "settings"])
        #expect(manifest["schemaVersion"] as? Int == 1)
        #expect(settings["intervalDays"] as? Int == 14)
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
        #expect(FileManager.default.fileExists(atPath: trackingURL.appendingPathComponent(entry.imageFileName).path))
        #expect(!FileManager.default.fileExists(atPath: context.containerURL.appendingPathComponent("gallery").path))
    }

    @Test func schemaVersionOneLoadsHistoricalJPEGAndHEICCaptures() throws {
        let context = try makeContext()
        defer { cleanup(context) }
        let trackingURL = context.containerURL.appendingPathComponent("belly-tracking", isDirectory: true)
        try FileManager.default.createDirectory(at: trackingURL, withIntermediateDirectories: true)

        let jpegData = makeJPEGData(color: .systemOrange)
        let heicData = try makeHEICData()
        try jpegData.write(to: trackingURL.appendingPathComponent("legacy-capture.jpg"))
        try heicData.write(to: trackingURL.appendingPathComponent("native-capture.heic"))

        let manifestData = Data(
            """
            {
              "entries" : [
                {
                  "capturedAt" : "2026-02-10T08:00:00Z",
                  "id" : "0E9C6D3B-B04A-419B-8165-3DA71354291F",
                  "imageFileName" : "legacy-capture.jpg",
                  "pregnancyWeekAtCapture" : 20
                },
                {
                  "capturedAt" : "2026-03-10T08:00:00Z",
                  "id" : "970FECC3-1A8D-4E18-A5E6-C987E57C8690",
                  "imageFileName" : "native-capture.heic",
                  "pregnancyWeekAtCapture" : 24
                }
              ],
              "schemaVersion" : 1,
              "settings" : {
                "intervalDays" : 7
              }
            }
            """.utf8
        )
        try manifestData.write(to: trackingURL.appendingPathComponent("manifest.json"))

        let entries = context.dataSource.fetchBellyTrackingEntries()

        #expect(entries.map(\.imageFileName) == ["legacy-capture.jpg", "native-capture.heic"])
        #expect(context.dataSource.fetchBellyTrackingImageData(for: "legacy-capture.jpg") == jpegData)
        #expect(context.dataSource.fetchBellyTrackingImageData(for: "native-capture.heic") == heicData)
        #expect(BellyTrackingImageProcessor.fileExtension(for: jpegData) == "jpg")
        #expect(BellyTrackingImageProcessor.fileExtension(for: heicData) == "heic")
    }

    private func makeContext() throws -> MediaStorageTestContext {
        let containerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true)

        let suiteName = "MediaStorageContractTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        userDefaults.removePersistentDomain(forName: suiteName)
        let preferencesStore = UserDefaultsPreferencesStore(userDefaults: userDefaults)

        return MediaStorageTestContext(
            dataSource: BabyProgressDataSource(
                preferencesStore: preferencesStore,
                fileManager: .default,
                containerURL: containerURL
            ),
            suiteName: suiteName,
            userDefaults: userDefaults,
            preferencesStore: preferencesStore,
            containerURL: containerURL
        )
    }

    private func makeDataSource(_ context: MediaStorageTestContext) -> BabyProgressDataSource {
        BabyProgressDataSource(
            preferencesStore: context.preferencesStore,
            fileManager: .default,
            containerURL: context.containerURL
        )
    }

    private func cleanup(_ context: MediaStorageTestContext) {
        context.userDefaults.removePersistentDomain(forName: context.suiteName)

        do {
            try FileManager.default.removeItem(at: context.containerURL)
        } catch {
            Issue.record("Failed to remove test container: \(error)")
        }
    }

    private func makeJPEGData(color: UIColor) -> Data {
        let size = CGSize(width: 80, height: 120)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }

        return image.jpegData(compressionQuality: 1) ?? Data()
    }

    private func makeHEICData() throws -> Data {
        let sourceImage = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 400, height: 300))
        let colorSpace = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        return try #require(
            CIContext().heifRepresentation(
                of: sourceImage,
                format: .RGBA8,
                colorSpace: colorSpace,
                options: [:]
            )
        )
    }
}

private struct MediaStorageTestContext {
    let dataSource: BabyProgressDataSource
    let suiteName: String
    let userDefaults: UserDefaults
    let preferencesStore: UserDefaultsPreferencesStore
    let containerURL: URL
}

private extension Array {
    var onlyElement: Element? {
        count == 1 ? first : nil
    }
}
