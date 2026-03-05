import Foundation
import OSLog

public actor NetworkClient: NetworkClientProtocol {
    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let logger: Logger

    public init(
        baseUrl: String,
        session: URLSession = .shared,
        decoder: JSONDecoder = .init(),
        logger: Logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "AppNetwork",
            category: "Network"
        )
    ) {
        self.baseURL = baseUrl
        self.session = session
        self.decoder = decoder
        self.logger = logger
    }

    public func send<O: Decodable & Sendable>(_ request: NetworkRequest) async throws -> O {
        let url = try buildURL(path: request.path, query: request.query)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body

        var allHeaders = request.headers
        if request.body != nil, allHeaders["Content-Type"] == nil {
            allHeaders["Content-Type"] = "application/json"
        }
        if allHeaders["Accept"] == nil {
            allHeaders["Accept"] = "application/json"
        }
        allHeaders.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }

        logger.debug(
            "Request \(request.method.rawValue, privacy: .public) \(url.absoluteString, privacy: .public) bodyLength: \(request.body?.count ?? 0, privacy: .public)"
        )

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch let urlError as URLError {
            logger.error("Transport error: \(urlError.localizedDescription, privacy: .public)")
            throw NetworkError.transport(urlError)
        } catch {
            logger.error("Unknown transport error: \(String(describing: error), privacy: .public)")
            throw NetworkError.transportUnknown(description: String(describing: error))
        }

        guard let http = response as? HTTPURLResponse else {
            logger.error("Response was not HTTPURLResponse")
            throw NetworkError.nonHTTPResponse
        }

        logger.debug("Response status: \(http.statusCode, privacy: .public) bytes: \(data.count, privacy: .public)")

        switch http.statusCode {
        case 200 ..< 300:
            break
        case 401:
            throw NetworkError.unauthorized(body: data)
        default:
            throw NetworkError.server(statusCode: http.statusCode, body: data)
        }

        if let emptyResponse = EmptyResponse() as? O {
            return emptyResponse
        }

        guard !data.isEmpty else {
            throw NetworkError.emptyResponse
        }

        do {
            let decoded = try decoder.decode(O.self, from: data)
            logResponseBodyIfNeeded(data)
            return decoded
        } catch {
            logger.error("Decoding error: \(String(describing: error), privacy: .public)")
            throw NetworkError.decoding(description: String(describing: error), body: data)
        }
    }

    private func buildURL(path: String, query: [String: String]) throws -> URL {
        guard
            let base = URL(string: baseURL),
            var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        else {
            throw NetworkError.invalidURL(baseURL: baseURL, path: path)
        }

        components.path = normalizedPath(basePath: components.path, requestPath: path)

        let queryItems = query
            .filter { !$0.value.isEmpty }
            .sorted { $0.key < $1.key }
            .map { URLQueryItem(name: $0.key, value: $0.value) }
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw NetworkError.invalidURL(baseURL: baseURL, path: path)
        }

        return url
    }

    private func normalizedPath(basePath: String, requestPath: String) -> String {
        let baseSegments = basePath.split(separator: "/").map(String.init)
        let requestSegments = requestPath.split(separator: "/").map(String.init)
        let mergedSegments = baseSegments + requestSegments
        return "/" + mergedSegments.joined(separator: "/")
    }

    private func logResponseBodyIfNeeded(_ data: Data) {
#if DEBUG
        guard !data.isEmpty else { return }
        guard let body = String(data: data, encoding: .utf8) else { return }
        let previewLength = 512
        let preview = body.count > previewLength ? String(body.prefix(previewLength)) + "..." : body
        logger.debug("Response body preview: \(preview, privacy: .private)")
#endif
    }
}
