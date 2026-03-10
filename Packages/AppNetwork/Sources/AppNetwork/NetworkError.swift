import Foundation

public enum NetworkError: Error, Sendable {
    case invalidURL(baseURL: String, path: String)
    case nonHTTPResponse
    case transport(URLError)
    case transportUnknown(description: String)
    case unauthorized(body: Data)
    case server(statusCode: Int, body: Data)
    case emptyResponse
    case decoding(description: String, body: Data)
}
