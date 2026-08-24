import Foundation

public struct DeleteUltrasoundPhotoUseCase: DeleteUltrasoundPhotoUseCaseProtocol, Sendable {
    private let repository: any UltrasoundGalleryRepositoryProtocol

    public init(repository: any UltrasoundGalleryRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(id: String) async throws {
        try await repository.deletePhoto(id: id)
    }
}
