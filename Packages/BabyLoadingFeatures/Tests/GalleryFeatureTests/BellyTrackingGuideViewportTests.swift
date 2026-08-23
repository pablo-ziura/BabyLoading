@testable import GalleryFeature
import CoreGraphics
import Testing

@MainActor
struct BellyTrackingGuideViewportTests {
    @Test func photoAspectRatioFillsAvailableWidthWhenTheViewportIsTall() {
        let size = BellyTrackingGuideViewport(photoAspectRatio: 9 / 16)
            .size(in: CGSize(width: 390, height: 600))

        #expect(size == CGSize(width: 337.5, height: 600))
    }

    @Test func photoAspectRatioFillsAvailableHeightWhenTheViewportIsWide() {
        let size = BellyTrackingGuideViewport(photoAspectRatio: 9 / 16)
            .size(in: CGSize(width: 844, height: 390))

        #expect(size == CGSize(width: 219.375, height: 390))
    }

    @Test func invalidPhotoAspectRatioUsesThePortraitCaptureDefault() {
        let size = BellyTrackingGuideViewport(photoAspectRatio: 0)
            .size(in: CGSize(width: 390, height: 600))

        #expect(size == CGSize(width: 337.5, height: 600))
    }
}
