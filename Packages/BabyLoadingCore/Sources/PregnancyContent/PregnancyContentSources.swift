import Foundation

public protocol PregnancyContentSourceProtocol: Sendable {
    func loadDocument() async throws -> PregnancyContentDocument?
}

public struct BundlePregnancyContentSource: PregnancyContentSourceProtocol, Sendable {
    private let bundle: Bundle
    private let localization: PregnancyContentLocalization

    public init(
        bundle: Bundle,
        localization: PregnancyContentLocalization
    ) {
        self.bundle = bundle
        self.localization = localization
    }

    public func loadDocument() async throws -> PregnancyContentDocument? {
        guard let resourceURL = bundle.url(
            forResource: localization.resourceName,
            withExtension: "json"
        ) else {
            return nil
        }

        return try PregnancyContentDocument.decodeValidated(
            from: Data(contentsOf: resourceURL),
            expectedLocale: localization.localeCode
        )
    }
}

public actor LegacyPregnancyContentCacheStore: PregnancyContentSourceProtocol {
    private let localization: PregnancyContentLocalization
    private let fileManager: FileManager
    private let containerURL: URL

    public init(
        localization: PregnancyContentLocalization,
        containerURL: URL
    ) {
        self.localization = localization
        fileManager = FileManager()
        self.containerURL = containerURL
    }

    public func loadDocument() throws -> PregnancyContentDocument? {
        let fileURL = containerURL.appendingPathComponent(localization.fileName)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        return try PregnancyContentDocument.decodeValidated(
            from: Data(contentsOf: fileURL),
            expectedLocale: localization.localeCode
        )
    }
}

public struct EmptyPregnancyContentSource: PregnancyContentSourceProtocol, Sendable {
    public init() {}

    public func loadDocument() async throws -> PregnancyContentDocument? {
        nil
    }
}
