import Foundation

public protocol DeleteUltrasoundPhotoUseCaseProtocol: Sendable {
    func execute(id: String) async throws
}
