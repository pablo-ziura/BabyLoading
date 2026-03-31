import Foundation

#if canImport(UIKit)
    import UIKit
#endif

enum BellyTrackingImageProcessor {
    static func normalizedJPEGData(
        from data: Data,
        maxDimension: CGFloat = 2048,
        compressionQuality: CGFloat = 0.85
    ) -> Data? {
        #if canImport(UIKit)
            guard let image = UIImage(data: data) else { return nil }

            let targetSize = resizedSize(for: image.size, maxDimension: maxDimension)
            let format = UIGraphicsImageRendererFormat.default()
            format.scale = 1

            let renderedImage = UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }

            return renderedImage.jpegData(compressionQuality: compressionQuality)
        #else
            return nil
        #endif
    }

    #if canImport(UIKit)
        private static func resizedSize(for originalSize: CGSize, maxDimension: CGFloat) -> CGSize {
            guard originalSize.width > 0, originalSize.height > 0 else { return originalSize }

            let largestDimension = max(originalSize.width, originalSize.height)
            guard largestDimension > maxDimension else { return originalSize }

            let scale = maxDimension / largestDimension
            return CGSize(
                width: originalSize.width * scale,
                height: originalSize.height * scale
            )
        }
    #endif
}
