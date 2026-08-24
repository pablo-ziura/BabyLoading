@testable import BellyTracking
import Foundation
import ImageIO
import Testing

struct BellyTrackingImageProcessorTests {
    @Test func recognizesHistoricalJPEGAndNativeHEICData() throws {
        let jpegData = try BellyTrackingTestSupport.makeJPEGData()
        let heicData = try BellyTrackingTestSupport.makeHEICData()

        #expect(BellyTrackingImageProcessor.fileExtension(for: jpegData) == "jpg")
        #expect(BellyTrackingImageProcessor.fileExtension(for: heicData) == "heic")
        #expect(BellyTrackingImageProcessor.fileExtension(for: Data("invalid".utf8)) == nil)
    }

    @Test func cropsNewJPEGToTheGuidedPortraitAspectRatio() throws {
        let jpegData = try BellyTrackingTestSupport.makeJPEGData(
            width: 400,
            height: 300
        )

        let preparedImage = try BellyTrackingImageProcessor.prepareForStorage(jpegData)
        let properties = try BellyTrackingTestSupport.imageProperties(for: preparedImage.data)

        #expect(preparedImage.fileExtension == "jpg")
        #expect(properties[kCGImagePropertyPixelWidth] as? Int == 168)
        #expect(properties[kCGImagePropertyPixelHeight] as? Int == 300)
        #expect((properties[kCGImagePropertyOrientation] as? Int ?? 1) == 1)
    }

    @Test func cropsHEICToTheGuidedPortraitAspectRatio() throws {
        let sourceData = try BellyTrackingTestSupport.makeHEICData()

        let adjustedData = try #require(
            BellyTrackingImageProcessor.aspectAdjustedHEICData(from: sourceData)
        )
        let properties = try BellyTrackingTestSupport.imageProperties(for: adjustedData)

        #expect(properties[kCGImagePropertyPixelWidth] as? Int == 168)
        #expect(properties[kCGImagePropertyPixelHeight] as? Int == 300)
        #expect((properties[kCGImagePropertyOrientation] as? Int ?? 1) == 1)
    }

    @Test func materializesEXIFOrientationBeforeCroppingHEIC() throws {
        let orientedData = try BellyTrackingTestSupport.makeOrientedHEICData(
            exifOrientation: 6
        )

        let adjustedData = try #require(
            BellyTrackingImageProcessor.aspectAdjustedHEICData(from: orientedData)
        )
        let properties = try BellyTrackingTestSupport.imageProperties(for: adjustedData)

        #expect(properties[kCGImagePropertyPixelWidth] as? Int == 225)
        #expect(properties[kCGImagePropertyPixelHeight] as? Int == 400)
        #expect((properties[kCGImagePropertyOrientation] as? Int ?? 1) == 1)
    }

    @Test func materializesEXIFOrientationBeforeCroppingJPEG() throws {
        let orientedData = try BellyTrackingTestSupport.makeOrientedJPEGData(
            exifOrientation: 6
        )

        let preparedImage = try BellyTrackingImageProcessor.prepareForStorage(orientedData)
        let properties = try BellyTrackingTestSupport.imageProperties(for: preparedImage.data)

        #expect(preparedImage.fileExtension == "jpg")
        #expect(properties[kCGImagePropertyPixelWidth] as? Int == 225)
        #expect(properties[kCGImagePropertyPixelHeight] as? Int == 400)
        #expect((properties[kCGImagePropertyOrientation] as? Int ?? 1) == 1)
    }

    @Test func rejectsUnsupportedCaptureData() throws {
        do {
            _ = try BellyTrackingImageProcessor.prepareForStorage(Data("invalid".utf8))
            Issue.record("Unsupported capture data must throw")
        } catch let error as BellyTrackingStoreError {
            #expect(error == .unsupportedImageFormat)
        }
    }
}
