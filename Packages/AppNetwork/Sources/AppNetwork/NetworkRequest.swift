import Foundation

public struct NetworkRequest: Sendable {
    public var method: HTTPMethod
    public var path: String
    public var query: [String: String]
    public var headers: [String: String]
    public var body: Data?

    public init(
        method: HTTPMethod,
        path: String,
        query: [String: String] = [:],
        headers: [String: String] = [:],
        body: Data? = nil
    ) {
        self.method = method
        self.path = path
        self.query = query
        self.headers = headers
        self.body = body
    }
}

public struct EmptyResponse: Decodable, Sendable {
    public init() {}
}
