import Foundation

class BabyProgressDataSource: BabyProgressDataSourceProtocol {
    private let fileManager: FileManager
    private let containerURL: URL
    private let photosDirName = "gallery"
    private let bellyTrackingDirName = "belly-tracking"
    private let bellyTrackingManifestFileName = "manifest.json"
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    init(
        fileManager: FileManager,
        containerURL: URL
    ) {
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

    private var photosDirURL: URL? {
        let dir = containerURL.appendingPathComponent(photosDirName)
        ensureDirectoryExists(at: dir)
        return dir
    }

    private var bellyTrackingDirURL: URL? {
        let dir = containerURL.appendingPathComponent(bellyTrackingDirName)
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

    // MARK: - Ultrasound gallery

    func addUltrasoundPhoto(data: Data) {
        _ = storeUltrasoundPhoto(data: data)
    }

    func fetchUltrasoundPhotos() -> [UltrasoundPhoto] {
        guard let dir = photosDirURL else { return [] }
        do {
            let files = try fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.creationDateKey])
                .sorted { a, b in
                    let dateA = (try? a.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
                    let dateB = (try? b.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
                    return dateA < dateB
                }
            return files.compactMap { url in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return UltrasoundPhoto(id: url.lastPathComponent, data: data)
            }
        } catch {
            print("⚠️ [BabyProgressDataSource] Failed to read ultrasound gallery: \(error)")
            return []
        }
    }

    func deleteUltrasoundPhoto(id: String) {
        guard let dir = photosDirURL else { return }
        guard id == URL(fileURLWithPath: id).lastPathComponent else { return }

        let photoURL = dir.appendingPathComponent(id)
        guard fileManager.fileExists(atPath: photoURL.path) else { return }

        do {
            try fileManager.removeItem(at: photoURL)
            print("🗑️ [BabyProgressDataSource] Ultrasound photo deleted")
        } catch {
            print("⚠️ [BabyProgressDataSource] Failed to delete ultrasound photo: \(error)")
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
                return nil
            }

            return entry
        } catch {
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
    private func storeUltrasoundPhoto(data: Data, fileExtension: String = "jpg") -> URL? {
        guard let dir = photosDirURL else {
            print("⚠️ [BabyProgressDataSource] No gallery directory")
            return nil
        }

        let filename = "\(UUID().uuidString).\(fileExtension)"
        let url = dir.appendingPathComponent(filename)

        do {
            try data.write(to: url, options: .atomic)
            print("💾 [BabyProgressDataSource] Ultrasound photo saved (\(data.count) bytes)")
            return url
        } catch {
            print("⚠️ [BabyProgressDataSource] Failed to save ultrasound photo: \(error)")
            return nil
        }
    }
}
