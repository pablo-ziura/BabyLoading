import Foundation

enum PregnancyContentRemoteFetchResult: Equatable {
    case notModified
    case success(document: PregnancyContentDocument, eTag: String?)
}
