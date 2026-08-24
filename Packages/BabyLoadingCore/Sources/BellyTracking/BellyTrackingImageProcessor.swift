import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum BellyTrackingImageProcessor {
    public static let guidedPhotoAspectRatio: CGFloat = 9.0 / 16.0

    public static func fileExtension(for data: Data) -> String? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let typeIdentifier = CGImageSourceGetType(source),
              let type = UTType(typeIdentifier as String) else {
            return nil
        }

        switch type.identifier {
        case UTType.heic.identifier:
            return "heic"
        case UTType.jpeg.identifier:
            return "jpg"
        default:
            return nil
        }
    }

    public static func aspectAdjustedHEICData(from data: Data) -> Data? {
        guard fileExtension(for: data) == "heic" else {
            return nil
        }
        return aspectAdjustedData(from: data, outputFormat: .heic)
    }

    static func aspectAdjustedJPEGData(from data: Data) -> Data? {
        guard fileExtension(for: data) == "jpg" else {
            return nil
        }
        return aspectAdjustedData(from: data, outputFormat: .jpeg)
    }

    static func prepareForStorage(_ data: Data) throws -> (data: Data, fileExtension: String) {
        guard let fileExtension = fileExtension(for: data) else {
            throw BellyTrackingStoreError.unsupportedImageFormat
        }

        let adjustedData: Data?
        switch fileExtension {
        case "heic":
            adjustedData = aspectAdjustedHEICData(from: data)
        case "jpg":
            adjustedData = aspectAdjustedJPEGData(from: data)
        default:
            adjustedData = nil
        }
        guard let adjustedData else {
            throw BellyTrackingStoreError.imageProcessingFailed
        }

        return (adjustedData, fileExtension)
    }

    private static func aspectAdjustedData(
        from data: Data,
        outputFormat: OutputFormat
    ) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                as? [CFString: Any],
              let image = CIImage(data: data, options: [.applyOrientationProperty: false]) else {
            return nil
        }

        let exifOrientation = (properties[kCGImagePropertyOrientation] as? NSNumber)?.int32Value ?? 1
        let orientedImage = image.oriented(forExifOrientation: exifOrientation)
        let imageExtent = orientedImage.extent.integral
        guard imageExtent.width > 0, imageExtent.height > 0 else {
            return nil
        }

        let imageAspectRatio = imageExtent.width / imageExtent.height
        let cropSize: CGSize
        if abs(imageAspectRatio - guidedPhotoAspectRatio) <= 0.001 {
            cropSize = imageExtent.size
        } else if imageAspectRatio > guidedPhotoAspectRatio {
            cropSize = CGSize(
                width: floor(imageExtent.height * guidedPhotoAspectRatio),
                height: imageExtent.height
            )
        } else {
            cropSize = CGSize(
                width: imageExtent.width,
                height: floor(imageExtent.width / guidedPhotoAspectRatio)
            )
        }

        let cropRect = CGRect(
            x: floor(imageExtent.midX - cropSize.width / 2),
            y: floor(imageExtent.midY - cropSize.height / 2),
            width: cropSize.width,
            height: cropSize.height
        )
        let croppedImage = orientedImage
            .cropped(to: cropRect)
            .transformed(
                by: CGAffineTransform(
                    translationX: -cropRect.minX,
                    y: -cropRect.minY
                )
            )
            .settingProperties([
                kCGImagePropertyOrientation as String: 1,
                kCGImagePropertyTIFFDictionary as String: [
                    kCGImagePropertyTIFFOrientation as String: 1
                ]
            ])
        guard let colorSpace = image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB) else {
            return nil
        }

        let context = CIContext()
        switch outputFormat {
        case .heic:
            return context.heifRepresentation(
                of: croppedImage,
                format: .RGBA8,
                colorSpace: colorSpace,
                options: [:]
            )
        case .jpeg:
            return context.jpegRepresentation(
                of: croppedImage,
                colorSpace: colorSpace,
                options: [:]
            )
        }
    }

    private enum OutputFormat {
        case heic
        case jpeg
    }
}
