import Foundation

struct RemoteContentSource: PregnancyContentRemoteSourceProtocol {
    let session: URLSession
    let url: URL?

    var isEnabled: Bool { url != nil }

    func fetch(ifNoneMatch eTag: String?) async throws -> PregnancyContentRemoteFetchResult {
        guard let url else {
            throw PregnancyContentRemoteSourceError.missingURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15

        if let eTag, !eTag.isEmpty {
            request.setValue(eTag, forHTTPHeaderField: "If-None-Match")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PregnancyContentRemoteSourceError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            let document = try PregnancyContentDocument.decodeValidated(from: data)
            return .success(
                document: document,
                eTag: httpResponse.value(forHTTPHeaderField: "ETag")
            )
        case 304:
            return .notModified
        default:
            throw PregnancyContentRemoteSourceError.unexpectedStatus(httpResponse.statusCode)
        }
    }
}
