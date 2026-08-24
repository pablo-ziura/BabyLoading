import Foundation

public actor BellyTrackingStore: BellyTrackingStoreProtocol {
    public static let directoryName = "belly-tracking"
    public static let manifestFileName = "manifest.json"

    private let fileManager: FileManager
    private let containerURL: URL

    public init(containerURL: URL) {
        fileManager = FileManager()
        self.containerURL = containerURL
    }

    public func loadTimeline() throws -> [BellyTrackingEntry] {
        try loadManifest().entries.sorted { $0.capturedAt < $1.capturedAt }
    }

    public func loadImageData(imageFileName: String) throws -> Data? {
        guard isValidImageFileName(imageFileName) else {
            throw BellyTrackingStoreError.invalidImageFileName(imageFileName)
        }

        let imageURL = try trackingDirectoryURL().appendingPathComponent(imageFileName)
        guard let itemType = try existingItemType(at: imageURL) else {
            return nil
        }
        guard itemType == .typeRegular else {
            throw BellyTrackingStoreError.invalidImageFileName(imageFileName)
        }
        return try Data(contentsOf: imageURL)
    }

    public func capturePhoto(
        data: Data,
        capturedAt: Date,
        pregnancyWeekAtCapture: Int?
    ) throws -> BellyTrackingEntry {
        let preparedImage = try BellyTrackingImageProcessor.prepareForStorage(data)
        var manifest = try loadManifest()
        let imageFileName = "\(UUID().uuidString).\(preparedImage.fileExtension)"
        let imageURL = try trackingDirectoryURL().appendingPathComponent(imageFileName)
        let entry = BellyTrackingEntry(
            imageFileName: imageFileName,
            capturedAt: normalizedForManifest(capturedAt),
            pregnancyWeekAtCapture: pregnancyWeekAtCapture
        )

        try preparedImage.data.write(to: imageURL, options: .atomic)

        do {
            manifest.entries.append(entry)
            try saveManifest(manifest)
            return entry
        } catch {
            do {
                try fileManager.removeItem(at: imageURL)
            } catch let rollbackError {
                throw BellyTrackingStoreError.rollbackFailed(
                    operation: String(describing: error),
                    rollback: String(describing: rollbackError)
                )
            }
            throw error
        }
    }

    public func deleteEntry(id: UUID) throws {
        let originalManifest = try loadManifest()
        guard let entryIndex = originalManifest.entries.firstIndex(where: { $0.id == id }) else {
            return
        }

        var updatedManifest = originalManifest
        let entry = updatedManifest.entries.remove(at: entryIndex)
        guard isValidImageFileName(entry.imageFileName) else {
            throw BellyTrackingStoreError.invalidImageFileName(entry.imageFileName)
        }

        let imageURL = try trackingDirectoryURL().appendingPathComponent(entry.imageFileName)
        let imageItemType = try existingItemType(at: imageURL)
        if let imageItemType, imageItemType != .typeRegular {
            throw BellyTrackingStoreError.invalidImageFileName(entry.imageFileName)
        }

        try saveManifest(updatedManifest)
        guard imageItemType != nil else {
            return
        }

        do {
            try fileManager.removeItem(at: imageURL)
        } catch {
            do {
                try saveManifest(originalManifest)
            } catch let rollbackError {
                throw BellyTrackingStoreError.rollbackFailed(
                    operation: String(describing: error),
                    rollback: String(describing: rollbackError)
                )
            }
            throw error
        }
    }

    public func loadSettings() throws -> BellyTrackingSettings {
        try loadManifest().settings
    }

    public func updateSettings(_ settings: BellyTrackingSettings) throws {
        var manifest = try loadManifest()
        manifest.settings = settings
        try saveManifest(manifest)
    }

    private func trackingDirectoryURL() throws -> URL {
        let directoryURL = containerURL.appendingPathComponent(Self.directoryName, isDirectory: true)
        if let itemType = try existingItemType(at: directoryURL) {
            guard itemType == .typeDirectory else {
                throw BellyTrackingStoreError.invalidTrackingDirectory
            }
        } else {
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
        }
        return directoryURL
    }

    private func manifestURL() throws -> URL {
        let url = try trackingDirectoryURL().appendingPathComponent(Self.manifestFileName)
        if let itemType = try existingItemType(at: url), itemType != .typeRegular {
            throw BellyTrackingStoreError.invalidManifestFile
        }
        return url
    }

    private func loadManifest() throws -> BellyTrackingManifest {
        let manifestURL = try manifestURL()
        guard fileManager.fileExists(atPath: manifestURL.path) else {
            return .empty
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let manifest = try decoder.decode(
            BellyTrackingManifest.self,
            from: Data(contentsOf: manifestURL)
        )
        guard manifest.schemaVersion == BellyTrackingManifest.currentSchemaVersion else {
            throw BellyTrackingStoreError.unsupportedManifestSchema(manifest.schemaVersion)
        }
        for entry in manifest.entries where !isValidImageFileName(entry.imageFileName) {
            throw BellyTrackingStoreError.invalidImageFileName(entry.imageFileName)
        }
        var entryIdentifiers: Set<UUID> = []
        var normalizedImageFileNames: Set<String> = []
        for entry in manifest.entries {
            guard entryIdentifiers.insert(entry.id).inserted else {
                throw BellyTrackingStoreError.duplicateEntryIdentifier(entry.id)
            }
            guard normalizedImageFileNames.insert(entry.imageFileName.lowercased()).inserted else {
                throw BellyTrackingStoreError.duplicateImageFileName(entry.imageFileName)
            }
        }

        return BellyTrackingManifest(
            schemaVersion: BellyTrackingManifest.currentSchemaVersion,
            settings: BellyTrackingSettings(intervalDays: manifest.settings.intervalDays),
            entries: manifest.entries.sorted { $0.capturedAt < $1.capturedAt }
        )
    }

    private func saveManifest(_ manifest: BellyTrackingManifest) throws {
        let normalizedManifest = BellyTrackingManifest(
            schemaVersion: BellyTrackingManifest.currentSchemaVersion,
            settings: BellyTrackingSettings(intervalDays: manifest.settings.intervalDays),
            entries: manifest.entries.sorted { $0.capturedAt < $1.capturedAt }
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(normalizedManifest)
        try data.write(to: manifestURL(), options: .atomic)
    }

    private func isValidImageFileName(_ fileName: String) -> Bool {
        let supportedExtensions = ["heic", "jpeg", "jpg"]
        return !fileName.isEmpty
            && fileName != "."
            && fileName != ".."
            && !fileName.contains("/")
            && !fileName.contains("\\")
            && fileName == URL(fileURLWithPath: fileName).lastPathComponent
            && supportedExtensions.contains(
                URL(fileURLWithPath: fileName).pathExtension.lowercased()
            )
    }

    private func existingItemType(at url: URL) throws -> FileAttributeType? {
        do {
            return try fileManager.attributesOfItem(atPath: url.path)[.type]
                as? FileAttributeType
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return nil
        }
    }

    private func normalizedForManifest(_ date: Date) -> Date {
        Date(timeIntervalSince1970: floor(date.timeIntervalSince1970))
    }
}
