@testable import BabyLoading
import CoreGraphics
import Testing

@MainActor
struct BellyTrackingGuideViewportTests {
    @Test func photoAspectRatio_FillsAvailableWidthWhenTheViewportIsTall() {
        let size = BellyTrackingGuideViewport(photoAspectRatio: 9 / 16)
            .size(in: CGSize(width: 390, height: 600))

        #expect(size == CGSize(width: 337.5, height: 600))
    }

    @Test func photoAspectRatio_FillsAvailableHeightWhenTheViewportIsWide() {
        let size = BellyTrackingGuideViewport(photoAspectRatio: 9 / 16)
            .size(in: CGSize(width: 844, height: 390))

        #expect(size == CGSize(width: 219.375, height: 390))
    }

    @Test func invalidPhotoAspectRatio_UsesThePortraitCaptureDefault() {
        let size = BellyTrackingGuideViewport(photoAspectRatio: 0)
            .size(in: CGSize(width: 390, height: 600))

        #expect(size == CGSize(width: 337.5, height: 600))
    }
}
