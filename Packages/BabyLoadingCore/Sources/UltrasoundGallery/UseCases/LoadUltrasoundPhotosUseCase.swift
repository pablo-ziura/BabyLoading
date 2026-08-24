import Foundation

public struct LoadUltrasoundPhotosUseCase: LoadUltrasoundPhotosUseCaseProtocol, Sendable {
    private let repository: any UltrasoundGalleryRepositoryProtocol

    public init(repository: any UltrasoundGalleryRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> [UltrasoundPhoto] {
        try await repository.loadPhotos()
    }
}
