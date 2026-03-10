import Foundation

enum PregnancyContentRemoteSourceError: Error, Equatable {
    case missingURL
    case invalidResponse
    case unexpectedStatus(Int)
}
