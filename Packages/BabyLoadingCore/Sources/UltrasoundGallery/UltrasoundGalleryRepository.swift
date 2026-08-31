import Foundation

public actor UltrasoundGalleryRepository: UltrasoundGalleryRepositoryProtocol {
    private let store: any UltrasoundGalleryStoreProtocol

    public init(store: any UltrasoundGalleryStoreProtocol) {
        self.store = store
    }

    public func loadPhotos() async throws -> [UltrasoundPhoto] {
        try await store.loadPhotos()
    }

    public func addPhoto(image: ValidatedUltrasoundImage) async throws -> UltrasoundPhoto {
        try await store.addPhoto(image: image)
    }

    public func deletePhoto(id: String) async throws {
        try await store.deletePhoto(id: id)
    }
}
