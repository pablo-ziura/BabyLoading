import Foundation

public protocol LoadUltrasoundPhotosUseCaseProtocol: Sendable {
    func execute() async throws -> [UltrasoundPhoto]
}
