import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import UltrasoundGallery

struct UltrasoundGalleryTestContext {
    let containerURL: URL

    init() throws {
        containerURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: containerURL,
            withIntermediateDirectories: true
        )
    }

    func remove() {
        do {
            try FileManager.default.removeItem(at: containerURL)
        } catch {
            Issue.record("Failed to remove test container: \(error)")
        }
    }
}

func makeUltrasoundImageData(
    format: UltrasoundImageFormat,
    width: Int = 2,
    height: Int = 2,
    imageCount: Int = 1
) throws -> Data {
    let type: UTType = switch format {
    case .jpeg:
        .jpeg
    case .heic:
        .heic
    case .png:
        .png
    }
    return try makeImageData(type: type, width: width, height: height, imageCount: imageCount)
}

func makeUnsupportedImageData() throws -> Data {
    try makeImageData(type: .gif, width: 2, height: 2, imageCount: 1)
}

func makeImageDataWithInvalidDimensions() throws -> Data {
    var data = try makeImageData(type: .png, width: 2, height: 2, imageCount: 1)
    data.replaceSubrange(16 ..< 20, with: [0, 0, 0, 0])
    return data
}

private func makeImageData(
    type: UTType,
    width: Int,
    height: Int,
    imageCount: Int
) throws -> Data {
    let mutableData = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(
        mutableData,
        type.identifier as CFString,
        imageCount,
        nil
    ) else {
        throw UltrasoundGalleryTestSupportError.destinationCreationFailed(type.identifier)
    }
    let image = try makeImage(width: width, height: height)

    for _ in 0 ..< imageCount {
        CGImageDestinationAddImage(destination, image, nil)
    }
    guard CGImageDestinationFinalize(destination) else {
        throw UltrasoundGalleryTestSupportError.imageEncodingFailed(type.identifier)
    }

    return mutableData as Data
}

private func makeImage(width: Int, height: Int) throws -> CGImage {
    let bytesPerRow = width * 4
    let data = Data(repeating: 0x7F, count: bytesPerRow * height)
    guard let provider = CGDataProvider(data: data as CFData),
          let image = CGImage(
              width: width,
              height: height,
              bitsPerComponent: 8,
              bitsPerPixel: 32,
              bytesPerRow: bytesPerRow,
              space: CGColorSpaceCreateDeviceRGB(),
              bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
              provider: provider,
              decode: nil,
              shouldInterpolate: false,
              intent: .defaultIntent
          ) else {
        throw UltrasoundGalleryTestSupportError.imageCreationFailed
    }
    return image
}

private enum UltrasoundGalleryTestSupportError: Error {
    case destinationCreationFailed(String)
    case imageEncodingFailed(String)
    case imageCreationFailed
}
