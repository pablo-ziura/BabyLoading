import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import UltrasoundGallery
import UniformTypeIdentifiers

public actor BackupJPEGPreparer: BackupImagePreparingProtocol {
    private let validator: any UltrasoundImageValidatorProtocol
    private let context = CIContext()

    public init(validator: any UltrasoundImageValidatorProtocol) {
        self.validator = validator
    }

    public func prepareJPEG(from source: URL, to destination: URL) throws {
        try Task.checkCancellation()
        guard source.standardizedFileURL != destination.standardizedFileURL else { throw BackupFailure.invalidData }
        let data = try Data(contentsOf: source, options: .mappedIfSafe)
        do { _ = try validator.validate(data) } catch { throw BackupFailure.invalidData }
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let image = CIImage(data: data, options: [.applyOrientationProperty: false]) else {
            throw BackupFailure.invalidData
        }
        let orientation = (properties[kCGImagePropertyOrientation] as? NSNumber)?.int32Value ?? 1
        let oriented = image.oriented(forExifOrientation: orientation)
        let extent = oriented.extent.integral
        let white = CIImage(color: CIColor(red: 1, green: 1, blue: 1)).cropped(to: extent)
        guard let rendered = context.createCGImage(oriented.composited(over: white), from: extent) else {
            throw BackupFailure.invalidData
        }
        let output = NSMutableData()
        guard let encoder = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw BackupFailure.invalidData
        }
        CGImageDestinationAddImage(encoder, rendered, [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary)
        guard CGImageDestinationFinalize(encoder) else { throw BackupFailure.invalidData }
        let jpeg = try removingEXIF(output as Data)
        do { _ = try validator.validate(jpeg) } catch { throw BackupFailure.invalidData }
        try Task.checkCancellation()
        try jpeg.write(to: destination, options: .atomic)
    }

    // ImageIO generates EXIF dimensions; remove APP1 segments without recompressing the pixels.
    private func removingEXIF(_ data: Data) throws -> Data {
        guard data.count >= 4, data[0] == 0xff, data[1] == 0xd8 else { throw BackupFailure.invalidData }
        var result = Data(data.prefix(2))
        var offset = 2
        while offset + 3 < data.count {
            guard data[offset] == 0xff else { throw BackupFailure.invalidData }
            let marker = data[offset + 1]
            if marker == 0xda {
                result.append(data[offset...])
                return result
            }
            let length = Int(data[offset + 2]) * 256 + Int(data[offset + 3])
            guard length >= 2, offset + 2 + length <= data.count else { throw BackupFailure.invalidData }
            if marker != 0xe1 { result.append(data[offset..<(offset + 2 + length)]) }
            offset += 2 + length
        }
        throw BackupFailure.invalidData
    }

    public func validateDownloadedJPEG(at url: URL) throws {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        do {
            let image = try validator.validate(data)
            guard image.format == .jpeg,
                  let source = CGImageSourceCreateWithData(data as CFData, nil),
                  CGImageSourceCreateImageAtIndex(source, 0, nil) != nil else { throw BackupFailure.invalidData }
        } catch { throw BackupFailure.invalidData }
    }
}
