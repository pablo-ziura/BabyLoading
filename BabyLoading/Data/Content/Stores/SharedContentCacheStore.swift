import Foundation

final class SharedContentCacheStore: PregnancyContentCacheStoreProtocol {
    private let fileManager: FileManager
    private let fileName: String
    private let localization: PregnancyContentLocalization

    init(
        localization: PregnancyContentLocalization,
        fileManager: FileManager = .default,
        fileName: String? = nil
    ) {
        self.localization = localization
        self.fileManager = fileManager
        self.fileName = fileName ?? localization.fileName
    }

    private var fileURL: URL? {
        SharedAppGroup.containerURL(fileManager: fileManager)?.appendingPathComponent(fileName)
    }

    func loadDocument() -> PregnancyContentDocument? {
        guard let fileURL,
              fileManager.fileExists(atPath: fileURL.path),
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
