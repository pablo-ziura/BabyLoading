import CloudBackup
import CoreGraphics
import Foundation
import ImageIO
import Testing
import UltrasoundGallery
import UniformTypeIdentifiers

struct BackupJPEGPreparerTests {
    @Test func conversionPreservesOriginalAndMaterializesOrientationWithoutEXIF() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let original = try fixture(type: .jpeg, orientation: 6)
        let source = root.appendingPathComponent("original.jpg")
        let destination = root.appendingPathComponent("backup.jpg")
        try original.write(to: source)
        let preparer = BackupJPEGPreparer(validator: UltrasoundImageValidator(policy: .standard))
        try await preparer.prepareJPEG(from: source, to: destination)
        #expect(try Data(contentsOf: source) == original)
        let image = try #require(CGImageSourceCreateWithURL(destination as CFURL, nil))
        let properties = try #require(CGImageSourceCopyPropertiesAtIndex(image, 0, nil) as? [CFString: Any])
        #expect(properties[kCGImagePropertyPixelWidth] as? Int == 12)
        #expect(properties[kCGImagePropertyPixelHeight] as? Int == 20)
        #expect(properties[kCGImagePropertyExifDictionary] == nil)
        #expect(properties[kCGImagePropertyGPSDictionary] == nil)
        try await preparer.validateDownloadedJPEG(at: destination)
    }

    @Test func transparencyIsFlattenedOntoWhite() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("original.png")
        let destination = root.appendingPathComponent("backup.jpg")
        try fixture(type: .png, orientation: 1).write(to: source)
        let preparer = BackupJPEGPreparer(validator: UltrasoundImageValidator(policy: .standard))
        try await preparer.prepareJPEG(from: source, to: destination)
        let imageSource = try #require(CGImageSourceCreateWithURL(destination as CFURL, nil))
        let image = try #require(CGImageSourceCreateImageAtIndex(imageSource, 0, nil))
        let context = try #require(CGContext(
            data: nil, width: 20, height: 12, bitsPerComponent: 8, bytesPerRow: 80,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.draw(image, in: CGRect(x: 0, y: 0, width: 20, height: 12))
        let pixel = try #require(context.data).assumingMemoryBound(to: UInt8.self)
        #expect(pixel[0] > 245 && pixel[1] > 245 && pixel[2] > 245)
    }

    @Test func invalidOriginalRemainsAvailableAfterConversionFailure() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("original.heic")
        let destination = root.appendingPathComponent("backup.jpg")
        let data = Data([1, 2, 3])
        try data.write(to: source)
        let preparer = BackupJPEGPreparer(validator: UltrasoundImageValidator(policy: .standard))
        await #expect(throws: BackupFailure.invalidData) {
            try await preparer.prepareJPEG(from: source, to: destination)
        }
        #expect(try Data(contentsOf: source) == data)
        #expect(!FileManager.default.fileExists(atPath: destination.path))
    }

    private func fixture(type: UTType, orientation: Int) throws -> Data {
        let context = try #require(CGContext(
            data: nil, width: 20, height: 12, bitsPerComponent: 8, bytesPerRow: 80,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        let image = try #require(context.makeImage())
        let data = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(data, type.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, [
            kCGImagePropertyOrientation: orientation,
            kCGImagePropertyExifDictionary: [kCGImagePropertyExifUserComment: "Private metadata"]
        ] as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        return data as Data
    }
}
