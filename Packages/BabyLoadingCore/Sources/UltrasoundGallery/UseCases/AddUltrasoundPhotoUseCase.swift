import Foundation

public struct AddUltrasoundPhotoUseCase: AddUltrasoundPhotoUseCaseProtocol, Sendable {
    private let validator: any UltrasoundImageValidatorProtocol
    private let repository: any UltrasoundGalleryRepositoryProtocol

    public init(
        validator: any UltrasoundImageValidatorProtocol,
        repository: any UltrasoundGalleryRepositoryProtocol
    ) {
        self.validator = validator
        self.repository = repository
    }

    public func execute(data: Data) async throws -> UltrasoundPhoto {
        let image = try validator.validate(data)
        return try await repository.addPhoto(image: image)
    }
}
