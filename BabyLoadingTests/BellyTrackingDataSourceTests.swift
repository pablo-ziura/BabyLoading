@testable import BabyLoading
import AppPreferences
import CoreImage
import Foundation
import ImageIO
import Testing
import UIKit
import UniformTypeIdentifiers

struct BellyTrackingDataSourceTests {
    @Test func bellyTrackingPersistsManifestAcrossDataSourceInstances() throws {
        let context = try makeContext()
        defer { cleanup(context) }

        let capturedAt = try #require(isoDate("2026-03-01T09:30:00Z"))

        context.dataSource.saveBellyTrackingSettings(BellyTrackingSettings(intervalDays: 14))
        let imageData = makeImageData(color: .systemPink)
        let entry = try #require(
            context.dataSource.saveBellyTrackingPhoto(
                data: imageData,
                capturedAt: capturedAt,
                pregnancyWeekAtCapture: 22
            )
        )

        let reloadedDataSource = makeDataSource(context: context)

        #expect(reloadedDataSource.fetchBellyTrackingSettings() == BellyTrackingSettings(intervalDays: 14))
        #expect(reloadedDataSource.fetchBellyTrackingEntries() == [entry])
        #expect(entry.imageFileName.hasSuffix(".jpg"))
        #expect(reloadedDataSource.fetchBellyTrackingImageData(for: entry.imageFileName) == imageData)
        #expect(reloadedDataSource.fetchAllPhotos() == [imageData])
    }

    @Test func bellyTrackingEntriesAreReturnedInChronologicalOrder() throws {
        let context = try makeContext()
        defer { cleanup(context) }

        let firstDate = try #require(isoDate("2026-02-10T08:00:00Z"))
        let secondDate = try #require(isoDate("2026-03-10T08:00:00Z"))

        _ = context.dataSource.saveBellyTrackingPhoto(
            data: makeImageData(color: .systemBlue),
            capturedAt: secondDate,
            pregnancyWeekAtCapture: 24
        )
        _ = context.dataSource.saveBellyTrackingPhoto(
            data: makeImageData(color: .systemGreen),
            capturedAt: firstDate,
            pregnancyWeekAtCapture: 20
        )

        let fetchedEntries = context.dataSource.fetchBellyTrackingEntries()

        #expect(fetchedEntries.map(\.capturedAt) == [firstDate, secondDate])
    }

    @Test func deleteBellyTrackingEntryRemovesImageAndEntry() throws {
        let context = try makeContext()
        defer { cleanup(context) }
        let capturedAt = try #require(isoDate("2026-03-20T10:00:00Z"))

        let entry = try #require(
            context.dataSource.saveBellyTrackingPhoto(
                data: makeImageData(color: .systemOrange),
                capturedAt: capturedAt,
                pregnancyWeekAtCapture: 26
            )
        )

        context.dataSource.deleteBellyTrackingEntry(id: entry.id)

        #expect(context.dataSource.fetchBellyTrackingEntries().isEmpty)
        #expect(context.dataSource.fetchBellyTrackingImageData(for: entry.imageFileName) == nil)
    }

    @Test func HEICCapture_IsStoredInTheRequestedPortraitAspectRatio() throws {
        let sourceImage = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 400, height: 300))
        let colorSpace = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        let sourceData = try #require(
            CIContext().heifRepresentation(
                of: sourceImage,
                format: .RGBA8,
                colorSpace: colorSpace,
                options: [:]
            )
        )

        let adjustedData = try #require(
            BellyTrackingImageProcessor.aspectAdjustedHEICData(from: sourceData)
        )
        let source = try #require(CGImageSourceCreateWithData(adjustedData as CFData, nil))
        let properties = try #require(
            CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        )

        #expect(BellyTrackingImageProcessor.fileExtension(for: adjustedData) == "heic")
        #expect(properties[kCGImagePropertyPixelWidth] as? Int == 168)
        #expect(properties[kCGImagePropertyPixelHeight] as? Int == 300)
    }

    @Test func HEICCapture_AppliesEXIFOrientationOnlyOnce() throws {
        let sourceImage = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 400, height: 300))
        let colorSpace = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        let sourceData = try #require(
            CIContext().heifRepresentation(
                of: sourceImage,
                format: .RGBA8,
                colorSpace: colorSpace,
                options: [:]
            )
        )
        let imageSource = try #require(CGImageSourceCreateWithData(sourceData as CFData, nil))
        let orientedData = NSMutableData()
        let destination = try #require(
            CGImageDestinationCreateWithData(
                orientedData,
                UTType.heic.identifier as CFString,
                1,
                nil
            )
        )
        CGImageDestinationAddImageFromSource(
            destination,
            imageSource,
            0,
            [kCGImagePropertyOrientation: 6] as CFDictionary
        )
        #expect(CGImageDestinationFinalize(destination))

        let adjustedData = try #require(
            BellyTrackingImageProcessor.aspectAdjustedHEICData(from: orientedData as Data)
        )
        let adjustedSource = try #require(CGImageSourceCreateWithData(adjustedData as CFData, nil))
        let properties = try #require(
            CGImageSourceCopyPropertiesAtIndex(adjustedSource, 0, nil) as? [CFString: Any]
        )

        #expect(properties[kCGImagePropertyPixelWidth] as? Int == 225)
        #expect(properties[kCGImagePropertyPixelHeight] as? Int == 400)
        #expect((properties[kCGImagePropertyOrientation] as? Int ?? 1) == 1)
    }

    private func makeContext() throws -> DataSourceTestContext {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)

        let suiteName = "BellyTrackingDataSourceTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        userDefaults.removePersistentDomain(forName: suiteName)

        return DataSourceTestContext(
            dataSource: BabyProgressDataSource(
                preferencesStore: UserDefaultsPreferencesStore(userDefaults: userDefaults),
                fileManager: .default,
                containerURL: temporaryDirectory
            ),
            suiteName: suiteName,
            userDefaults: userDefaults,
            containerURL: temporaryDirectory
        )
    }

    private func makeDataSource(context: DataSourceTestContext) -> BabyProgressDataSource {
        BabyProgressDataSource(
            preferencesStore: UserDefaultsPreferencesStore(userDefaults: context.userDefaults),
            fileManager: .default,
            containerURL: context.containerURL
        )
    }

    private func cleanup(_ context: DataSourceTestContext) {
        context.userDefaults.removePersistentDomain(forName: context.suiteName)
        try? FileManager.default.removeItem(at: context.containerURL)
    }

    private func isoDate(_ string: String) -> Date? {
        ISO8601DateFormatter().date(from: string)
    }

    private func makeImageData(color: UIColor) -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 80, height: 120))
        let image = renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: 80, height: 120)))
        }

        return image.jpegData(compressionQuality: 1) ?? Data()
    }
}

private struct DataSourceTestContext {
    let dataSource: BabyProgressDataSource
    let suiteName: String
    let userDefaults: UserDefaults
    let containerURL: URL
}
