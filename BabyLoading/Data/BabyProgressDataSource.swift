import Foundation

protocol BabyProgressDataSourceProtocol {
    func save(date: Date?)
    func fetchDate() -> Date?
    func savePhoto(data: Data?)
    func fetchPhoto() -> Data?
    func deletePhoto()
}

class BabyProgressDataSource: BabyProgressDataSourceProtocol {
    private let suiteName = "group.com.pablo.BabyLoading"
    private let photoFileName = "user_photo.jpg"

    private var photoFileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: suiteName)?
            .appendingPathComponent(photoFileName)
    }

    func save(date: Date?) {
        print("💾 [BabyProgressDataSource] save -> \(String(describing: date)) (suite: \(suiteName))")
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            print("⚠️ [BabyProgressDataSource] Failed to init UserDefaults with suite: \(suiteName)")
            return
        }
        defaults.set(date, forKey: "eventDate")
    }

    func fetchDate() -> Date? {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            print("⚠️ [BabyProgressDataSource] Failed to init UserDefaults with suite: \(suiteName)")
            return nil
        }
        let date = defaults.object(forKey: "eventDate") as? Date
        print("🔍 [BabyProgressDataSource] fetchDate -> \(String(describing: date)) (suite: \(suiteName))")
        return date
    }

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
}
