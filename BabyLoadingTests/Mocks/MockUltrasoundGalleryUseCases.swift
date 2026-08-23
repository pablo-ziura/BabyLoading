import Foundation
import UltrasoundGallery

enum MockUltrasoundGalleryError: Error {
    case operationFailed
}

@MainActor
final class MockLoadUltrasoundPhotosUseCase: LoadUltrasoundPhotosUseCaseProtocol {
    var result: [UltrasoundPhoto] = []
    var error: (any Error)?
    private(set) var executeCallCount = 0

    func execute() async throws -> [UltrasoundPhoto] {
        executeCallCount += 1
        if let error {
            throw error
        }
        return result
    }
}

@MainActor
final class MockAddUltrasoundPhotoUseCase: AddUltrasoundPhotoUseCaseProtocol {
    var error: (any Error)?
    private(set) var executeCallCount = 0
    private(set) var addedData: Data?

    func execute(data: Data) async throws -> UltrasoundPhoto {
        executeCallCount += 1
        addedData = data
        if let error {
            throw error
        }
        return UltrasoundPhoto(id: "added-photo.jpg", data: data)
    }
}

@MainActor
final class MockDeleteUltrasoundPhotoUseCase: DeleteUltrasoundPhotoUseCaseProtocol {
    var error: (any Error)?
    private(set) var executeCallCount = 0
    private(set) var deletedIdentifier: String?

    func execute(id: String) async throws {
        executeCallCount += 1
        deletedIdentifier = id
        if let error {
            throw error
        }
    }
}
