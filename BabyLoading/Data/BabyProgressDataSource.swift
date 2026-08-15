import Foundation

protocol BabyProgressDataSourceProtocol {
    func save(date: Date?)
    func fetchDate() -> Date?
    func savePhoto(data: Data?)
    func fetchPhoto() -> Data?
    func deletePhoto()

    // Multi-photo support
    func addPhoto(data: Data)
    func fetchAllPhotos() -> [Data]
    func deletePhoto(at index: Int)

    // Belly tracking
    func fetchBellyTrackingEntries() -> [BellyTrackingEntry]
    func fetchBellyTrackingImageData(for imageFileName: String) -> Data?
    func saveBellyTrackingPhoto(
        data: Data,
        capturedAt: Date,
        pregnancyWeekAtCapture: Int?
    ) -> BellyTrackingEntry?
    func deleteBellyTrackingEntry(id: UUID)
    func fetchBellyTrackingSettings() -> BellyTrackingSettings
    func saveBellyTrackingSettings(_ settings: BellyTrackingSettings)
}

class BabyProgressDataSource: BabyProgressDataSourceProtocol {
    private let suiteName: String
    private let userDefaults: UserDefaults?
    private let fileManager: FileManager
    private let containerURL: URL?
    private let photoFileName = "user_photo.jpg"
    private let photosDirName = "gallery"
    private let bellyTrackingDirName = "belly-tracking"
    private let bellyTrackingManifestFileName = "manifest.json"
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    init(
        suiteName: String = SharedAppGroup.identifier,
        userDefaults: UserDefaults? = SharedAppGroup.userDefaults(),
        fileManager: FileManager = .default,
        containerURL: URL? = SharedAppGroup.containerURL()
    ) {
        self.suiteName = suiteName
        self.userDefaults = userDefaults
        self.fileManager = fileManager
        self.containerURL = containerURL

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        jsonEncoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        jsonDecoder = decoder
    }

    private var photoFileURL: URL? {
        containerURL?.appendingPathComponent(photoFileName)
    }

    private var photosDirURL: URL? {
        guard let container = containerURL else { return nil }
        let dir = container.appendingPathComponent(photosDirName)
        ensureDirectoryExists(at: dir)
        return dir
    }

    private var bellyTrackingDirURL: URL? {
        guard let container = containerURL else { return nil }
        let dir = container.appendingPathComponent(bellyTrackingDirName)
        ensureDirectoryExists(at: dir)
        return dir
    }

    private var bellyTrackingManifestURL: URL? {
        bellyTrackingDirURL?.appendingPathComponent(bellyTrackingManifestFileName)
    }

    private func ensureDirectoryExists(at url: URL) {
        guard !fileManager.fileExists(atPath: url.path) else { return }
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func save(date: Date?) {
        print("💾 [BabyProgressDataSource] save lastPeriodDate -> \(String(describing: date)) (suite: \(suiteName))")
        guard let userDefaults else {
            print("⚠️ [BabyProgressDataSource] Failed to init UserDefaults with suite: \(suiteName)")
            return
        }
        userDefaults.set(date, forKey: "lastPeriodDate")
    }

    func fetchDate() -> Date? {
        guard let userDefaults else {
            print("⚠️ [BabyProgressDataSource] Failed to init UserDefaults with suite: \(suiteName)")
            return nil
        }

        if let lastPeriodDate = userDefaults.object(forKey: "lastPeriodDate") as? Date {
            print("🔍 [BabyProgressDataSource] fetchDate -> lastPeriodDate found: \(lastPeriodDate)")
            return lastPeriodDate
        }

        return nil
    }

    // MARK: - Single photo (legacy, used by widget)

    func savePhoto(data: Data?) {
        guard let url = photoFileURL else {
            print("⚠️ [BabyProgressDataSource] No container URL for photo")
            return
        }
        guard let data else {
            deletePhoto()
            return
        }
        do {
            try data.write(to: url, options: .atomic)
            print("💾 [BabyProgressDataSource] Photo saved (\(data.count) bytes)")
        } catch {
            print("⚠️ [BabyProgressDataSource] Failed to save photo: \(error)")
        }
    }

    func fetchPhoto() -> Data? {
        guard let url = photoFileURL,
              fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        return try? Data(contentsOf: url)
    }

    func deletePhoto() {
        guard let url = photoFileURL else { return }
        try? fileManager.removeItem(at: url)
        print("🗑️ [BabyProgressDataSource] Photo deleted")
    }

    // MARK: - Multi-photo gallery

    func addPhoto(data: Data) {
        _ = storeGalleryPhoto(data: data)
    }

    func fetchAllPhotos() -> [Data] {
        guard let dir = photosDirURL else { return [] }
        do {
            let files = try fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.creationDateKey])
                .sorted { a, b in
                    let dateA = (try? a.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
                    let dateB = (try? b.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
                    return dateA < dateB
                }
            return files.compactMap { try? Data(contentsOf: $0) }
        } catch {
            print("⚠️ [BabyProgressDataSource] Failed to read gallery: \(error)")
            return []
        }
    }

    func deletePhoto(at index: Int) {
        guard let dir = photosDirURL else { return }
        do {
            let files = try fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.creationDateKey])
                .sorted { a, b in
                    let dateA = (try? a.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
                    let dateB = (try? b.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
                    return dateA < dateB
                }
            guard index >= 0 && index < files.count else { return }
            try fileManager.removeItem(at: files[index])
            print("🗑️ [BabyProgressDataSource] Gallery photo deleted at index \(index)")
        } catch {
            print("⚠️ [BabyProgressDataSource] Failed to delete gallery photo: \(error)")
        }
    }

    // MARK: - Belly tracking

    func fetchBellyTrackingEntries() -> [BellyTrackingEntry] {
        loadBellyTrackingManifest().entries.sorted { $0.capturedAt < $1.capturedAt }
    }

    func fetchBellyTrackingImageData(for imageFileName: String) -> Data? {
        guard let imageURL = bellyTrackingDirURL?.appendingPathComponent(imageFileName),
              fileManager.fileExists(atPath: imageURL.path) else {
            return nil
        }

        return try? Data(contentsOf: imageURL)
    }

    func saveBellyTrackingPhoto(
        data: Data,
        capturedAt: Date,
        pregnancyWeekAtCapture: Int?
    ) -> BellyTrackingEntry? {
        guard let bellyTrackingDirURL else {
            print("⚠️ [BabyProgressDataSource] No belly tracking directory")
            return nil
        }

        guard let fileExtension = BellyTrackingImageProcessor.fileExtension(for: data) else {
            print("⚠️ [BabyProgressDataSource] Unsupported belly tracking photo format")
            return nil
        }

        let storedData: Data
        if fileExtension == "heic" {
            guard let aspectAdjustedData = BellyTrackingImageProcessor.aspectAdjustedHEICData(from: data) else {
                print("⚠️ [BabyProgressDataSource] Failed to apply the belly tracking photo aspect ratio")
                return nil
            }
            storedData = aspectAdjustedData
        } else {
            storedData = data
        }

        guard let galleryPhotoURL = storeGalleryPhoto(data: storedData, fileExtension: fileExtension) else {
            return nil
        }

        let imageFileName = "\(UUID().uuidString).\(fileExtension)"
        let imageURL = bellyTrackingDirURL.appendingPathComponent(imageFileName)
        let entry = BellyTrackingEntry(
            imageFileName: imageFileName,
            capturedAt: capturedAt,
            pregnancyWeekAtCapture: pregnancyWeekAtCapture
        )

        do {
            try storedData.write(to: imageURL, options: .atomic)

            var manifest = loadBellyTrackingManifest()
            manifest.entries.append(entry)
            manifest.entries.sort { $0.capturedAt < $1.capturedAt }

            guard saveBellyTrackingManifest(manifest) else {
                try? fileManager.removeItem(at: imageURL)
                try? fileManager.removeItem(at: galleryPhotoURL)
                return nil
            }

            return entry
        } catch {
            try? fileManager.removeItem(at: galleryPhotoURL)
            print("⚠️ [BabyProgressDataSource] Failed to save belly tracking photo: \(error)")
            return nil
        }
    }

    func deleteBellyTrackingEntry(id: UUID) {
        var manifest = loadBellyTrackingManifest()
        guard let index = manifest.entries.firstIndex(where: { $0.id == id }) else { return }

        let entry = manifest.entries.remove(at: index)
        let imageURL = bellyTrackingDirURL?.appendingPathComponent(entry.imageFileName)

        if let imageURL, fileManager.fileExists(atPath: imageURL.path) {
            try? fileManager.removeItem(at: imageURL)
        }

        _ = saveBellyTrackingManifest(manifest)
    }

    func fetchBellyTrackingSettings() -> BellyTrackingSettings {
        loadBellyTrackingManifest().settings
    }

    func saveBellyTrackingSettings(_ settings: BellyTrackingSettings) {
        var manifest = loadBellyTrackingManifest()
        manifest.settings = settings
        _ = saveBellyTrackingManifest(manifest)
    }

    private func loadBellyTrackingManifest() -> BellyTrackingManifest {
        guard let manifestURL = bellyTrackingManifestURL,
              fileManager.fileExists(atPath: manifestURL.path) else {
            return .empty
        }

        do {
            let data = try Data(contentsOf: manifestURL)
            let manifest = try jsonDecoder.decode(BellyTrackingManifest.self, from: data)
            guard manifest.schemaVersion == BellyTrackingManifest.currentSchemaVersion else {
                print("⚠️ [BabyProgressDataSource] Unsupported belly tracking manifest version: \(manifest.schemaVersion)")
                return .empty
            }

            return BellyTrackingManifest(
                schemaVersion: BellyTrackingManifest.currentSchemaVersion,
                settings: manifest.settings,
                entries: manifest.entries
            )
        } catch {
            print("⚠️ [BabyProgressDataSource] Failed to load belly tracking manifest: \(error)")
            return .empty
        }
    }

    @discardableResult
    private func saveBellyTrackingManifest(_ manifest: BellyTrackingManifest) -> Bool {
        guard let manifestURL = bellyTrackingManifestURL else {
            print("⚠️ [BabyProgressDataSource] No belly tracking manifest URL")
            return false
        }

        let normalizedManifest = BellyTrackingManifest(
            schemaVersion: BellyTrackingManifest.currentSchemaVersion,
            settings: BellyTrackingSettings(intervalDays: manifest.settings.intervalDays),
            entries: manifest.entries.sorted { $0.capturedAt < $1.capturedAt }
        )

        do {
            let data = try jsonEncoder.encode(normalizedManifest)
            try data.write(to: manifestURL, options: .atomic)
            return true
        } catch {
            print("⚠️ [BabyProgressDataSource] Failed to save belly tracking manifest: \(error)")
            return false
        }
    }

    @discardableResult
    private func storeGalleryPhoto(data: Data, fileExtension: String = "jpg") -> URL? {
        guard let dir = photosDirURL else {
            print("⚠️ [BabyProgressDataSource] No gallery directory")
            return nil
        }

        let filename = "\(UUID().uuidString).\(fileExtension)"
        let url = dir.appendingPathComponent(filename)

        do {
            try data.write(to: url, options: .atomic)
            print("💾 [BabyProgressDataSource] Gallery photo saved (\(data.count) bytes)")
            return url
        } catch {
            print("⚠️ [BabyProgressDataSource] Failed to save gallery photo: \(error)")
            return nil
        }
    }
}
