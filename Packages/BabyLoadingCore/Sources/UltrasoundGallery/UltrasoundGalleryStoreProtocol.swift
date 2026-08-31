import Foundation

public protocol UltrasoundGalleryStoreProtocol: Sendable {
    func loadPhotos() async throws -> [UltrasoundPhoto]
    func addPhoto(image: ValidatedUltrasoundImage) async throws -> UltrasoundPhoto
    func deletePhoto(id: String) async throws
}
