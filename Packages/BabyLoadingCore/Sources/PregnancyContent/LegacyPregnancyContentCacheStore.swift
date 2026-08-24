import Foundation

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
