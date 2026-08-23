import BellyTracking
import CoreGraphics

struct BellyTrackingGuideViewport {
    static let defaultPhotoAspectRatio = BellyTrackingImageProcessor.guidedPhotoAspectRatio

    private let photoAspectRatio: CGFloat

    init(photoAspectRatio: CGFloat) {
        self.photoAspectRatio = photoAspectRatio.isFinite && photoAspectRatio > 0
            ? photoAspectRatio
            : Self.defaultPhotoAspectRatio
    }

    func size(in availableSize: CGSize) -> CGSize {
        guard availableSize.width > 0, availableSize.height > 0 else {
            return .zero
        }

        let availableAspectRatio = availableSize.width / availableSize.height

        if availableAspectRatio > photoAspectRatio {
            return CGSize(
                width: availableSize.height * photoAspectRatio,
                height: availableSize.height
            )
        }

        return CGSize(
            width: availableSize.width,
            height: availableSize.width / photoAspectRatio
        )
    }
}
