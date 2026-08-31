import Foundation

public protocol UltrasoundGalleryRepositoryProtocol: Sendable {
    func loadPhotos() async throws -> [UltrasoundPhoto]
    func addPhoto(image: ValidatedUltrasoundImage) async throws -> UltrasoundPhoto
    func deletePhoto(id: String) async throws
}
