import Foundation

final class SharedContentCacheStore: PregnancyContentCacheStoreProtocol {
    private let fileManager: FileManager
    private let defaults: UserDefaults?
    private let fileName: String
    private let localization: PregnancyContentLocalization

    init(
        localization: PregnancyContentLocalization,
        fileManager: FileManager = .default,
        defaults: UserDefaults? = SharedAppGroup.userDefaults(),
        fileName: String? = nil
    ) {
        self.localization = localization
        self.fileManager = fileManager
        self.defaults = defaults
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

    @discardableResult
    func saveDocument(_ document: PregnancyContentDocument) -> Bool {
        guard let fileURL else {
            return false
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(document) else {
            return false
        }

        do {
            try data.write(to: fileURL, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    var eTag: String? {
        get { defaults?.string(forKey: localization.metadataKey("eTag")) }
        set { defaults?.set(newValue, forKey: localization.metadataKey("eTag")) }
    }

    var lastFetchAt: Date? {
        get { defaults?.object(forKey: localization.metadataKey("lastFetchAt")) as? Date }
        set { defaults?.set(newValue, forKey: localization.metadataKey("lastFetchAt")) }
    }

    var revision: Int? {
        get {
            let key = localization.metadataKey("revision")
            guard defaults?.object(forKey: key) != nil else {
                return nil
            }
            return defaults?.integer(forKey: key)
        }
        set { defaults?.set(newValue, forKey: localization.metadataKey("revision")) }
    }
}
