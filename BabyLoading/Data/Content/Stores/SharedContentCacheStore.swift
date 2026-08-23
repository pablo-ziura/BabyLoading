import Foundation

final class SharedContentCacheStore: PregnancyContentCacheStoreProtocol {
    private let fileManager: FileManager
    private let fileURL: URL
    private let localization: PregnancyContentLocalization

    init(
        localization: PregnancyContentLocalization,
        fileManager: FileManager,
        containerURL: URL
    ) {
        self.localization = localization
        self.fileManager = fileManager
        fileURL = containerURL.appendingPathComponent(localization.fileName)
    }

    func loadDocument() -> PregnancyContentDocument? {
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL)
        else {
            return nil
        }

        return try? PregnancyContentDocument.decodeValidated(
            from: data,
            expectedLocale: localization.localeCode
        )
    }
}
