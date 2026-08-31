import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum UltrasoundImageFormat: Equatable, Sendable {
    case jpeg
    case heic
    case png

    public var fileExtension: String {
        switch self {
        case .jpeg:
            "jpg"
        case .heic:
            "heic"
        case .png:
            "png"
        }
    }
}

public struct ValidatedUltrasoundImage: Equatable, Sendable {
    public let data: Data
    public let format: UltrasoundImageFormat
    public let pixelWidth: Int
    public let pixelHeight: Int

}

public struct UltrasoundImageValidationPolicy: Equatable, Sendable {
    public static let standard = UltrasoundImageValidationPolicy(
        maximumEncodedByteCount: 25 * 1_024 * 1_024,
        maximumPixelCount: 48_000_000,
        maximumPixelDimension: 12_000
    )

    public let maximumEncodedByteCount: Int
    public let maximumPixelCount: Int
    public let maximumPixelDimension: Int

    public init(
        maximumEncodedByteCount: Int,
        maximumPixelCount: Int,
        maximumPixelDimension: Int
    ) {
        precondition(maximumEncodedByteCount > 0)
        precondition(maximumPixelCount > 0)
        precondition(maximumPixelDimension > 0)
        self.maximumEncodedByteCount = maximumEncodedByteCount
        self.maximumPixelCount = maximumPixelCount
        self.maximumPixelDimension = maximumPixelDimension
    }
}

public enum UltrasoundImageValidationError: Error, Equatable, Sendable {
    case emptyData
    case encodedDataTooLarge
    case invalidImageData
    case unsupportedFormat
    case multiframeImage
    case invalidPixelDimensions
    case pixelDimensionsTooLarge
    case pixelCountTooLarge
}

public protocol UltrasoundImageValidatorProtocol: Sendable {
    func validate(_ data: Data) throws -> ValidatedUltrasoundImage
}

public struct UltrasoundImageValidator: UltrasoundImageValidatorProtocol, Sendable {
    private let policy: UltrasoundImageValidationPolicy

    public init(policy: UltrasoundImageValidationPolicy) {
        self.policy = policy
    }

    public func validate(_ data: Data) throws -> ValidatedUltrasoundImage {
        guard !data.isEmpty else {
            throw UltrasoundImageValidationError.emptyData
        }
        guard data.count <= policy.maximumEncodedByteCount else {
            throw UltrasoundImageValidationError.encodedDataTooLarge
        }

        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, options) else {
            throw UltrasoundImageValidationError.invalidImageData
        }
        let imageCount = CGImageSourceGetCount(source)
        guard imageCount > 0 else {
            throw UltrasoundImageValidationError.invalidImageData
        }
        guard imageCount == 1 else {
            throw UltrasoundImageValidationError.multiframeImage
        }
        guard let typeIdentifier = CGImageSourceGetType(source),
              let format = format(for: typeIdentifier as String) else {
            throw UltrasoundImageValidationError.unsupportedFormat
        }
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, options)
            as? [CFString: Any],
              let pixelWidth = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue,
              let pixelHeight = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue,
              pixelWidth > 0,
              pixelHeight > 0 else {
            throw UltrasoundImageValidationError.invalidPixelDimensions
        }
        guard pixelWidth <= policy.maximumPixelDimension,
              pixelHeight <= policy.maximumPixelDimension else {
            throw UltrasoundImageValidationError.pixelDimensionsTooLarge
        }

        let (pixelCount, overflow) = pixelWidth.multipliedReportingOverflow(by: pixelHeight)
        guard !overflow, pixelCount <= policy.maximumPixelCount else {
            throw UltrasoundImageValidationError.pixelCountTooLarge
        }

        return ValidatedUltrasoundImage(
            data: data,
            format: format,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight
        )
    }

    private func format(for typeIdentifier: String) -> UltrasoundImageFormat? {
        guard let type = UTType(typeIdentifier) else { return nil }

        if type.conforms(to: .jpeg) {
            return .jpeg
        }
        if type.conforms(to: .heic) {
            return .heic
        }
        if type.conforms(to: .png) {
            return .png
        }
        return nil
    }
}
