import Foundation

public actor UltrasoundGalleryStore: UltrasoundGalleryStoreProtocol {
    public static let directoryName = "gallery"

    private let containerURL: URL
    private let fileManager: FileManager

    public init(containerURL: URL) {
        self.containerURL = containerURL
        fileManager = FileManager()
    }

    public func loadPhotos() throws -> [UltrasoundPhoto] {
        let properties: Set<URLResourceKey> = [
            .creationDateKey,
            .isRegularFileKey,
            .isSymbolicLinkKey
        ]
        let photoFiles = try fileManager.contentsOfDirectory(
            at: galleryDirectoryURL(),
            includingPropertiesForKeys: Array(properties),
            options: [.skipsHiddenFiles]
        )
        .compactMap { url -> (url: URL, creationDate: Date)? in
            let values = try url.resourceValues(forKeys: properties)
            guard values.isRegularFile == true, values.isSymbolicLink != true else {
                return nil
            }
            return (url, values.creationDate ?? .distantPast)
        }
        .sorted { firstPhoto, secondPhoto in
            if firstPhoto.creationDate == secondPhoto.creationDate {
                return firstPhoto.url.lastPathComponent < secondPhoto.url.lastPathComponent
            }
            return firstPhoto.creationDate < secondPhoto.creationDate
        }

        return try photoFiles.map { photoFile in
            UltrasoundPhoto(
                id: photoFile.url.lastPathComponent,
                data: try Data(contentsOf: photoFile.url)
            )
        }
    }

    public func addPhoto(data: Data) throws -> UltrasoundPhoto {
        let identifier = "\(UUID().uuidString).jpg"
        let fileURL = try galleryDirectoryURL().appendingPathComponent(identifier)
        try data.write(to: fileURL, options: .atomic)
        return UltrasoundPhoto(id: identifier, data: data)
    }

    public func deletePhoto(id: String) throws {
        let fileURL = try photoURL(for: id)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }
        try fileManager.removeItem(at: fileURL)
    }

    private func galleryDirectoryURL() throws -> URL {
        let directoryURL = containerURL.appendingPathComponent(
            Self.directoryName,
            isDirectory: true
        )
        if fileManager.fileExists(atPath: directoryURL.path) {
            let values = try directoryURL.resourceValues(
                forKeys: [.isDirectoryKey, .isSymbolicLinkKey]
            )
            guard values.isDirectory == true, values.isSymbolicLink != true else {
                throw UltrasoundGalleryStoreError.invalidGalleryDirectory
            }
        } else {
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
        }
        return directoryURL
    }

    private func photoURL(for identifier: String) throws -> URL {
        guard isValidPhotoIdentifier(identifier) else {
            throw UltrasoundGalleryStoreError.invalidPhotoIdentifier(identifier)
        }
        return try galleryDirectoryURL().appendingPathComponent(identifier)
    }

    private func isValidPhotoIdentifier(_ identifier: String) -> Bool {
        !identifier.isEmpty
            && identifier != "."
            && identifier != ".."
            && !identifier.contains("/")
            && !identifier.contains("\\")
            && identifier == URL(fileURLWithPath: identifier).lastPathComponent
    }
}

public enum UltrasoundGalleryStoreError: Error, Equatable, Sendable {
    case invalidGalleryDirectory
    case invalidPhotoIdentifier(String)
}
