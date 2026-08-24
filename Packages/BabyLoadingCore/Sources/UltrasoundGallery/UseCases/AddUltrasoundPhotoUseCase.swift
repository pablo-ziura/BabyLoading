import Foundation

public struct AddUltrasoundPhotoUseCase: AddUltrasoundPhotoUseCaseProtocol, Sendable {
    private let repository: any UltrasoundGalleryRepositoryProtocol

    public init(repository: any UltrasoundGalleryRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(data: Data) async throws -> UltrasoundPhoto {
        try await repository.addPhoto(data: data)
    }
}
