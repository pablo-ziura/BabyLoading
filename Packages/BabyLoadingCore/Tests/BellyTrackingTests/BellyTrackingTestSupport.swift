@testable import BellyTracking
import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

enum BellyTrackingTestSupport {
    static func makeContainer() throws -> URL {
        let containerURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: containerURL,
            withIntermediateDirectories: true
        )
        return containerURL
    }

    static func removeContainer(_ containerURL: URL) {
        do {
            try FileManager.default.removeItem(at: containerURL)
        } catch {
            Issue.record("Failed to remove test container: \(error)")
        }
    }

    static func makeJPEGData(
        width: CGFloat = 80,
        height: CGFloat = 120
    ) throws -> Data {
        let image = makeImage(width: width, height: height)
        let colorSpace = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        return try #require(CIContext().jpegRepresentation(
            of: image,
            colorSpace: colorSpace,
            options: [:]
        ))
    }

    static func makeHEICData(
        width: CGFloat = 400,
        height: CGFloat = 300
    ) throws -> Data {
        let image = makeImage(width: width, height: height)
        let colorSpace = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        return try #require(CIContext().heifRepresentation(
            of: image,
            format: .RGBA8,
            colorSpace: colorSpace,
            options: [:]
        ))
    }

    static func makeOrientedHEICData(exifOrientation: Int) throws -> Data {
        try makeOrientedData(
            makeHEICData(),
            typeIdentifier: UTType.heic.identifier,
            exifOrientation: exifOrientation
        )
    }

    static func makeOrientedJPEGData(exifOrientation: Int) throws -> Data {
        try makeOrientedData(
            makeJPEGData(width: 400, height: 300),
            typeIdentifier: UTType.jpeg.identifier,
            exifOrientation: exifOrientation
        )
    }

    static func imageProperties(for data: Data) throws -> [CFString: Any] {
        let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
        return try #require(
            CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        )
    }

    static func date(_ value: String) throws -> Date {
        try #require(ISO8601DateFormatter().date(from: value))
    }

    private static func makeOrientedData(
        _ imageData: Data,
        typeIdentifier: String,
        exifOrientation: Int
    ) throws -> Data {
        let source = try #require(CGImageSourceCreateWithData(imageData as CFData, nil))
        let destinationData = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(
            destinationData,
            typeIdentifier as CFString,
            1,
            nil
        ))
        CGImageDestinationAddImageFromSource(
            destination,
            source,
            0,
            [kCGImagePropertyOrientation: exifOrientation] as CFDictionary
        )
        #expect(CGImageDestinationFinalize(destination))
        return destinationData as Data
    }

    private static func makeImage(width: CGFloat, height: CGFloat) -> CIImage {
        CIImage(color: .red).cropped(
            to: CGRect(x: 0, y: 0, width: width, height: height)
        )
    }
}
