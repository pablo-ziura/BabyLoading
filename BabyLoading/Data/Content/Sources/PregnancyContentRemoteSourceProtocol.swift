import Foundation

protocol PregnancyContentRemoteSourceProtocol {
    var isEnabled: Bool { get }
    func fetch(ifNoneMatch eTag: String?) async throws -> PregnancyContentRemoteFetchResult
}
