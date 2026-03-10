import Foundation

final class SharedContentCacheStore: PregnancyContentCacheStoreProtocol {
    private enum Keys {
        static let eTag = "pregnancyContentETag"
        static let lastFetchAt = "pregnancyContentLastFetchAt"
        static let revision = "pregnancyContentRevision"
    }

    private let fileManager: FileManager
    private let defaults: UserDefaults?
    private let fileName: String

    init(
        fileManager: FileManager = .default,
        defaults: UserDefaults? = SharedAppGroup.userDefaults(),
        fileName: String = "pregnancy-content.es.json"
    ) {
        self.fileManager = fileManager
        self.defaults = defaults
        self.fileName = fileName
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

        return try? PregnancyContentDocument.decodeValidated(from: data)
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
        get { defaults?.string(forKey: Keys.eTag) }
        set { defaults?.set(newValue, forKey: Keys.eTag) }
    }

    var lastFetchAt: Date? {
        get { defaults?.object(forKey: Keys.lastFetchAt) as? Date }
        set { defaults?.set(newValue, forKey: Keys.lastFetchAt) }
    }

    var revision: Int? {
        get {
            guard defaults?.object(forKey: Keys.revision) != nil else {
                return nil
            }
            return defaults?.integer(forKey: Keys.revision)
        }
        set { defaults?.set(newValue, forKey: Keys.revision) }
    }
}
