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
}

class BabyProgressDataSource: BabyProgressDataSourceProtocol {
    private let suiteName = "group.com.pablo.BabyLoading"
    private let photoFileName = "user_photo.jpg"
    private let photosDirName = "gallery"

    private var photoFileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: suiteName)?
            .appendingPathComponent(photoFileName)
    }

    private var photosDirURL: URL? {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suiteName) else { return nil }
        let dir = container.appendingPathComponent(photosDirName)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func save(date: Date?) {
        print("💾 [BabyProgressDataSource] save lastPeriodDate -> \(String(describing: date)) (suite: \(suiteName))")
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            print("⚠️ [BabyProgressDataSource] Failed to init UserDefaults with suite: \(suiteName)")
            return
        }
        defaults.set(date, forKey: "lastPeriodDate")
    }

    func fetchDate() -> Date? {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            print("⚠️ [BabyProgressDataSource] Failed to init UserDefaults with suite: \(suiteName)")
            return nil
        }

        if let lastPeriodDate = defaults.object(forKey: "lastPeriodDate") as? Date {
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
              FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        return try? Data(contentsOf: url)
    }

    func deletePhoto() {
        guard let url = photoFileURL else { return }
        try? FileManager.default.removeItem(at: url)
        print("🗑️ [BabyProgressDataSource] Photo deleted")
    }

    // MARK: - Multi-photo gallery

    func addPhoto(data: Data) {
        guard let dir = photosDirURL else {
            print("⚠️ [BabyProgressDataSource] No gallery directory")
            return
        }
        let filename = "\(UUID().uuidString).jpg"
        let url = dir.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            print("💾 [BabyProgressDataSource] Gallery photo saved (\(data.count) bytes)")
        } catch {
            print("⚠️ [BabyProgressDataSource] Failed to save gallery photo: \(error)")
        }
    }

    func fetchAllPhotos() -> [Data] {
        guard let dir = photosDirURL else { return [] }
        do {
            let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.creationDateKey])
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
            let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.creationDateKey])
                .sorted { a, b in
                    let dateA = (try? a.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
                    let dateB = (try? b.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
                    return dateA < dateB
                }
            guard index >= 0 && index < files.count else { return }
            try FileManager.default.removeItem(at: files[index])
            print("🗑️ [BabyProgressDataSource] Gallery photo deleted at index \(index)")
        } catch {
            print("⚠️ [BabyProgressDataSource] Failed to delete gallery photo: \(error)")
        }
    }
}
