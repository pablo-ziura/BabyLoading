import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum BellyTrackingImageProcessor {
    static let guidedPhotoAspectRatio: CGFloat = 9 / 16

    static func fileExtension(for data: Data) -> String? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let type = CGImageSourceGetType(source).flatMap({ UTType($0 as String) }) else {
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

    static func aspectAdjustedHEICData(from data: Data) -> Data? {
        guard fileExtension(for: data) == "heic",
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let image = CIImage(
                  data: data,
                  options: [.applyOrientationProperty: false]
              ) else {
            return nil
        }

        let exifOrientation = (properties[kCGImagePropertyOrientation] as? NSNumber)?.int32Value ?? 1
        let orientedImage = image.oriented(forExifOrientation: exifOrientation)
        let imageExtent = orientedImage.extent.integral
        guard imageExtent.width > 0, imageExtent.height > 0 else { return nil }

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
            .transformed(by: CGAffineTransform(translationX: -cropRect.minX, y: -cropRect.minY))
            .settingProperties([
                kCGImagePropertyOrientation as String: 1,
                kCGImagePropertyTIFFDictionary as String: [
                    kCGImagePropertyTIFFOrientation as String: 1
                ]
            ])
        let colorSpace = image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!

        return CIContext().heifRepresentation(
            of: croppedImage,
            format: .RGBA8,
            colorSpace: colorSpace,
            options: [:]
        )
    }
}
