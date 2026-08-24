import Foundation

public protocol AddUltrasoundPhotoUseCaseProtocol: Sendable {
    func execute(data: Data) async throws -> UltrasoundPhoto
}
