import Foundation
import Testing
@testable import UltrasoundGallery

struct UltrasoundGalleryTests {
    @Test func operationUseCasesPersistAndDeletePhotosByFileNameIdentity() async throws {
        let context = try TestContext()
        defer { context.remove() }
        let repository = UltrasoundGalleryRepository(
            store: UltrasoundGalleryStore(containerURL: context.containerURL)
        )
        let addPhoto = AddUltrasoundPhotoUseCase(repository: repository)
        let loadPhotos = LoadUltrasoundPhotosUseCase(repository: repository)
        let deletePhoto = DeleteUltrasoundPhotoUseCase(repository: repository)
        let photoData = Data([0x01, 0x02, 0x03])

        let photo = try await addPhoto.execute(data: photoData)
        let storedFileURL = context.containerURL
            .appendingPathComponent(UltrasoundGalleryStore.directoryName, isDirectory: true)
            .appendingPathComponent(photo.id)

        #expect(UltrasoundGalleryStore.directoryName == "gallery")
        #expect(photo.id.hasSuffix(".jpg"))
        #expect(photo.data == photoData)
        #expect(FileManager.default.fileExists(atPath: storedFileURL.path))
        #expect(
            try FileManager.default.contentsOfDirectory(
                at: context.containerURL,
                includingPropertiesForKeys: nil
            ).map(\.lastPathComponent) == [UltrasoundGalleryStore.directoryName]
        )
        #expect(try await loadPhotos.execute() == [photo])

        try await deletePhoto.execute(id: photo.id)

        #expect(try await loadPhotos.execute().isEmpty)
        #expect(!FileManager.default.fileExists(atPath: storedFileURL.path))
    }

    @Test func existingFilesRetainTheirFileNameIdentityAcrossStoreInstances() async throws {
        let context = try TestContext()
        defer { context.remove() }
        let galleryURL = context.containerURL.appendingPathComponent(
            UltrasoundGalleryStore.directoryName,
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: galleryURL,
            withIntermediateDirectories: true
        )
        let identifier = "existing-photo.jpeg"
        let photoData = Data([0x0A, 0x0B])
        try photoData.write(to: galleryURL.appendingPathComponent(identifier))

        let firstStore = UltrasoundGalleryStore(containerURL: context.containerURL)
        let firstLoad = try await firstStore.loadPhotos()
        let reloadedStore = UltrasoundGalleryStore(containerURL: context.containerURL)
        let secondLoad = try await reloadedStore.loadPhotos()

        #expect(firstLoad == [UltrasoundPhoto(id: identifier, data: photoData)])
        #expect(secondLoad == firstLoad)
    }

    @Test func concurrentAddsAreSerializedWithoutLosingPhotos() async throws {
        let context = try TestContext()
        defer { context.remove() }
        let repository = UltrasoundGalleryRepository(
            store: UltrasoundGalleryStore(containerURL: context.containerURL)
        )
        let addPhoto = AddUltrasoundPhotoUseCase(repository: repository)
        let loadPhotos = LoadUltrasoundPhotosUseCase(repository: repository)

        let addedPhotos = try await withThrowingTaskGroup(of: UltrasoundPhoto.self) { group in
            for byte in UInt8(0)..<UInt8(16) {
                group.addTask {
                    try await addPhoto.execute(data: Data([byte]))
                }
            }

            var photos: [UltrasoundPhoto] = []
            for try await photo in group {
                photos.append(photo)
            }
            return photos
        }
        let loadedPhotos = try await loadPhotos.execute()

        #expect(loadedPhotos.count == addedPhotos.count)
        #expect(Set(loadedPhotos.map(\.id)).count == addedPhotos.count)
        #expect(Set(loadedPhotos.map(\.data)) == Set(addedPhotos.map(\.data)))
    }

    @Test(
        arguments: [
            "",
            ".",
            "..",
            "../outside.jpg",
            "nested/photo.jpg",
            "nested\\photo.jpg"
        ]
    )
    func deletionRejectsInvalidPhotoIdentifiers(identifier: String) async throws {
        let context = try TestContext()
        defer { context.remove() }
        let store = UltrasoundGalleryStore(containerURL: context.containerURL)

        do {
            try await store.deletePhoto(id: identifier)
            Issue.record("Invalid photo identifiers must be rejected")
        } catch let error as UltrasoundGalleryStoreError {
            #expect(error == .invalidPhotoIdentifier(identifier))
        }

    }

    @Test func missingPhotoDeletionIsIdempotent() async throws {
        let context = try TestContext()
        defer { context.remove() }
        let store = UltrasoundGalleryStore(containerURL: context.containerURL)

        try await store.deletePhoto(id: "missing-photo.jpg")

        #expect(try await store.loadPhotos().isEmpty)
    }

    @Test func gallerySymbolicLinkCannotReadWriteOrDeleteOutsideTheContainer() async throws {
        let context = try TestContext()
        let outsideContext = try TestContext()
        defer {
            context.remove()
            outsideContext.remove()
        }
        let sentinelURL = outsideContext.containerURL.appendingPathComponent("sentinel.jpg")
        let sentinelData = Data([0xCA, 0xFE])
        try sentinelData.write(to: sentinelURL)
        try FileManager.default.createSymbolicLink(
            at: context.containerURL.appendingPathComponent(UltrasoundGalleryStore.directoryName),
            withDestinationURL: outsideContext.containerURL
        )
        let store = UltrasoundGalleryStore(containerURL: context.containerURL)

        do {
            _ = try await store.loadPhotos()
            Issue.record("A symbolic gallery directory must not be readable")
        } catch let error as UltrasoundGalleryStoreError {
            #expect(error == .invalidGalleryDirectory)
        }

        do {
            _ = try await store.addPhoto(data: Data([0x01]))
            Issue.record("A symbolic gallery directory must not be writable")
        } catch let error as UltrasoundGalleryStoreError {
            #expect(error == .invalidGalleryDirectory)
        }

        do {
            try await store.deletePhoto(id: sentinelURL.lastPathComponent)
            Issue.record("A symbolic gallery directory must not allow deletion")
        } catch let error as UltrasoundGalleryStoreError {
            #expect(error == .invalidGalleryDirectory)
        }

        #expect(try Data(contentsOf: sentinelURL) == sentinelData)
    }

    @Test func fileSystemFailuresArePropagated() async throws {
        let context = try TestContext()
        defer { context.remove() }
        let galleryURL = context.containerURL.appendingPathComponent(
            UltrasoundGalleryStore.directoryName
        )
        try Data([0x01]).write(to: galleryURL)
        let repository = UltrasoundGalleryRepository(
            store: UltrasoundGalleryStore(containerURL: context.containerURL)
        )
        let loadPhotos = LoadUltrasoundPhotosUseCase(repository: repository)
        let addPhoto = AddUltrasoundPhotoUseCase(repository: repository)
        let deletePhoto = DeleteUltrasoundPhotoUseCase(repository: repository)

        do {
            _ = try await loadPhotos.execute()
            Issue.record("File-system failures must propagate to the caller")
        } catch {
            #expect(error as? UltrasoundGalleryStoreError == .invalidGalleryDirectory)
        }

        do {
            _ = try await addPhoto.execute(data: Data([0x02]))
            Issue.record("File-system failures must propagate to the caller")
        } catch {
            #expect(error as? UltrasoundGalleryStoreError == .invalidGalleryDirectory)
        }

        do {
            try await deletePhoto.execute(id: "photo.jpg")
            Issue.record("File-system failures must propagate to the caller")
        } catch {
            #expect(error as? UltrasoundGalleryStoreError == .invalidGalleryDirectory)
        }

    }
}

private struct TestContext {
    let containerURL: URL

    init() throws {
        containerURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: containerURL,
            withIntermediateDirectories: true
        )
    }

    func remove() {
        do {
            try FileManager.default.removeItem(at: containerURL)
        } catch {
            Issue.record("Failed to remove test container: \(error)")
        }
    }
}
