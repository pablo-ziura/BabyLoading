import Foundation
import Testing
@testable import UltrasoundGallery

struct UltrasoundImageValidationTests {
    @Test func standardPolicyUsesTheAuditedLimits() {
        #expect(UltrasoundImageValidationPolicy.standard.maximumEncodedByteCount == 25 * 1_024 * 1_024)
        #expect(UltrasoundImageValidationPolicy.standard.maximumPixelCount == 48_000_000)
        #expect(UltrasoundImageValidationPolicy.standard.maximumPixelDimension == 12_000)
    }

    @Test(arguments: [
        UltrasoundImageFormat.jpeg,
        UltrasoundImageFormat.heic,
        UltrasoundImageFormat.png
    ])
    func supportedFormatsAreDetectedFromEncodedData(format: UltrasoundImageFormat) throws {
        let data = try makeUltrasoundImageData(format: format, width: 3, height: 2)
        let validator = UltrasoundImageValidator(policy: .standard)

        let image = try validator.validate(data)

        #expect(image.format == format)
        #expect(image.pixelWidth == 3)
        #expect(image.pixelHeight == 2)
        #expect(image.data == data)
    }

    @Test func emptyDataIsRejected() {
        let validator = UltrasoundImageValidator(policy: .standard)

        #expect(throws: UltrasoundImageValidationError.emptyData) {
            try validator.validate(Data())
        }
    }

    @Test func encodedSizeLimitIsEnforcedBeforeParsing() throws {
        let data = try makeUltrasoundImageData(format: .png)
        let validator = UltrasoundImageValidator(
            policy: UltrasoundImageValidationPolicy(
                maximumEncodedByteCount: data.count - 1,
                maximumPixelCount: 48_000_000,
                maximumPixelDimension: 12_000
            )
        )

        #expect(throws: UltrasoundImageValidationError.encodedDataTooLarge) {
            try validator.validate(data)
        }
    }

    @Test func corruptDataIsRejected() {
        let validator = UltrasoundImageValidator(policy: .standard)

        #expect(throws: UltrasoundImageValidationError.invalidImageData) {
            try validator.validate(Data([0xFF, 0xD8, 0xFF, 0x00]))
        }
    }

    @Test func unsupportedEncodedFormatIsRejected() throws {
        let data = try makeUnsupportedImageData()
        let validator = UltrasoundImageValidator(policy: .standard)

        #expect(throws: UltrasoundImageValidationError.unsupportedFormat) {
            try validator.validate(data)
        }
    }

    @Test func maximumDimensionIsEnforcedFromMetadata() throws {
        let data = try makeUltrasoundImageData(format: .png, width: 3, height: 2)
        let validator = UltrasoundImageValidator(
            policy: UltrasoundImageValidationPolicy(
                maximumEncodedByteCount: 25 * 1_024 * 1_024,
                maximumPixelCount: 48_000_000,
                maximumPixelDimension: 2
            )
        )

        #expect(throws: UltrasoundImageValidationError.pixelDimensionsTooLarge) {
            try validator.validate(data)
        }
    }

    @Test func maximumPixelCountIsEnforcedFromMetadata() throws {
        let data = try makeUltrasoundImageData(format: .jpeg, width: 3, height: 2)
        let validator = UltrasoundImageValidator(
            policy: UltrasoundImageValidationPolicy(
                maximumEncodedByteCount: 25 * 1_024 * 1_024,
                maximumPixelCount: 5,
                maximumPixelDimension: 12_000
            )
        )

        #expect(throws: UltrasoundImageValidationError.pixelCountTooLarge) {
            try validator.validate(data)
        }
    }

    @Test func exactConfiguredLimitsAreAccepted() throws {
        let data = try makeUltrasoundImageData(format: .png, width: 3, height: 2)
        let validator = UltrasoundImageValidator(
            policy: UltrasoundImageValidationPolicy(
                maximumEncodedByteCount: data.count,
                maximumPixelCount: 6,
                maximumPixelDimension: 3
            )
        )

        let image = try validator.validate(data)

        #expect(image.pixelWidth == 3)
        #expect(image.pixelHeight == 2)
    }

    @Test func invalidPixelDimensionsAreRejected() throws {
        let data = try makeImageDataWithInvalidDimensions()
        let validator = UltrasoundImageValidator(policy: .standard)

        #expect(throws: UltrasoundImageValidationError.invalidPixelDimensions) {
            try validator.validate(data)
        }
    }

    @Test func multiframeContainerIsRejected() throws {
        let data = try makeUltrasoundImageData(format: .heic, imageCount: 2)
        let validator = UltrasoundImageValidator(policy: .standard)

        #expect(throws: UltrasoundImageValidationError.multiframeImage) {
            try validator.validate(data)
        }
    }

    @Test(arguments: [
        UltrasoundImageFormat.jpeg,
        UltrasoundImageFormat.heic,
        UltrasoundImageFormat.png
    ])
    func useCasePersistsWithDetectedExtension(format: UltrasoundImageFormat) async throws {
        let context = try UltrasoundGalleryTestContext()
        defer { context.remove() }
        let repository = UltrasoundGalleryRepository(
            store: UltrasoundGalleryStore(containerURL: context.containerURL)
        )
        let useCase = AddUltrasoundPhotoUseCase(
            validator: UltrasoundImageValidator(policy: .standard),
            repository: repository
        )
        let data = try makeUltrasoundImageData(format: format)

        let photo = try await useCase.execute(data: data)

        #expect(photo.id.hasSuffix(".\(format.fileExtension)"))
        #expect(photo.data == data)
    }

    @Test func rejectedImportDoesNotCreatePartialFiles() async throws {
        let context = try UltrasoundGalleryTestContext()
        defer { context.remove() }
        let repository = UltrasoundGalleryRepository(
            store: UltrasoundGalleryStore(containerURL: context.containerURL)
        )
        let useCase = AddUltrasoundPhotoUseCase(
            validator: UltrasoundImageValidator(policy: .standard),
            repository: repository
        )

        await #expect(throws: UltrasoundImageValidationError.invalidImageData) {
            _ = try await useCase.execute(data: Data([0x01, 0x02]))
        }

        let galleryURL = context.containerURL.appendingPathComponent(
            UltrasoundGalleryStore.directoryName,
            isDirectory: true
        )
        #expect(!FileManager.default.fileExists(atPath: galleryURL.path))
    }
}
