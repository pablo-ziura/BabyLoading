import Foundation

public protocol UltrasoundGalleryRepositoryProtocol: Sendable {
    func loadPhotos() async throws -> [UltrasoundPhoto]
    func addPhoto(data: Data) async throws -> UltrasoundPhoto
    func deletePhoto(id: String) async throws
}

public actor UltrasoundGalleryRepository: UltrasoundGalleryRepositoryProtocol {
    private let store: any UltrasoundGalleryStoreProtocol

    public init(store: any UltrasoundGalleryStoreProtocol) {
        self.store = store
    }

    public func loadPhotos() async throws -> [UltrasoundPhoto] {
        try await store.loadPhotos()
    }

    public func addPhoto(data: Data) async throws -> UltrasoundPhoto {
        try await store.addPhoto(data: data)
    }

    public func deletePhoto(id: String) async throws {
        try await store.deletePhoto(id: id)
    }
}

public protocol LoadUltrasoundPhotosUseCaseProtocol: Sendable {
    func execute() async throws -> [UltrasoundPhoto]
}

public struct LoadUltrasoundPhotosUseCase: LoadUltrasoundPhotosUseCaseProtocol, Sendable {
    private let repository: any UltrasoundGalleryRepositoryProtocol

    public init(repository: any UltrasoundGalleryRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> [UltrasoundPhoto] {
        try await repository.loadPhotos()
    }
}

public protocol AddUltrasoundPhotoUseCaseProtocol: Sendable {
    func execute(data: Data) async throws -> UltrasoundPhoto
}

public struct AddUltrasoundPhotoUseCase: AddUltrasoundPhotoUseCaseProtocol, Sendable {
    private let repository: any UltrasoundGalleryRepositoryProtocol

    public init(repository: any UltrasoundGalleryRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(data: Data) async throws -> UltrasoundPhoto {
        try await repository.addPhoto(data: data)
    }
}

public protocol DeleteUltrasoundPhotoUseCaseProtocol: Sendable {
    func execute(id: String) async throws
}

public struct DeleteUltrasoundPhotoUseCase: DeleteUltrasoundPhotoUseCaseProtocol, Sendable {
    private let repository: any UltrasoundGalleryRepositoryProtocol

    public init(repository: any UltrasoundGalleryRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(id: String) async throws {
        try await repository.deletePhoto(id: id)
    }
}
