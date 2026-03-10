import Foundation

public protocol NetworkClientProtocol: Sendable {
    func send<O: Decodable & Sendable>(_ request: NetworkRequest) async throws -> O
}

public extension NetworkClientProtocol {
    func send(_ request: NetworkRequest) async throws {
        let _: EmptyResponse = try await send(request)
    }

    func get<O: Decodable & Sendable>(
        endpoint: String,
        params: [String: String]? = nil,
        headers: [String: String]? = nil
    ) async throws -> O {
        let request = NetworkRequest(
            method: .get,
            path: endpoint,
            query: params ?? [:],
            headers: headers ?? [:]
        )
        return try await send(request)
    }

    func post<O: Decodable & Sendable>(
        endpoint: String,
        params: [String: String]? = nil,
        headers: [String: String]? = nil,
        body: Data
    ) async throws -> O {
        let request = NetworkRequest(
            method: .post,
            path: endpoint,
            query: params ?? [:],
            headers: headers ?? [:],
            body: body
        )
        return try await send(request)
    }

    func put<O: Decodable & Sendable>(
        endpoint: String,
        params: [String: String]? = nil,
        headers: [String: String]? = nil,
        body: Data
    ) async throws -> O {
        let request = NetworkRequest(
            method: .put,
            path: endpoint,
            query: params ?? [:],
            headers: headers ?? [:],
            body: body
        )
        return try await send(request)
    }

    func patch<O: Decodable & Sendable>(
        endpoint: String,
        params: [String: String]? = nil,
        headers: [String: String]? = nil,
        body: Data
    ) async throws -> O {
        let request = NetworkRequest(
            method: .patch,
            path: endpoint,
            query: params ?? [:],
            headers: headers ?? [:],
            body: body
        )
        return try await send(request)
    }

    func delete<O: Decodable & Sendable>(
        endpoint: String,
        params: [String: String]? = nil,
        headers: [String: String]? = nil
    ) async throws -> O {
        let request = NetworkRequest(
            method: .delete,
            path: endpoint,
            query: params ?? [:],
            headers: headers ?? [:]
        )
        return try await send(request)
    }

    func post<I: Encodable, O: Decodable & Sendable>(
        endpoint: String,
        params: [String: String]? = nil,
        headers: [String: String]? = nil,
        data: I,
        encoder: JSONEncoder = .init()
    ) async throws -> O {
        let encoded = try encoder.encode(data)
        return try await post(
            endpoint: endpoint,
            params: params,
            headers: headers,
            body: encoded
        )
    }

    func put<I: Encodable, O: Decodable & Sendable>(
        endpoint: String,
        params: [String: String]? = nil,
        headers: [String: String]? = nil,
        data: I,
        encoder: JSONEncoder = .init()
    ) async throws -> O {
        let encoded = try encoder.encode(data)
        return try await put(
            endpoint: endpoint,
            params: params,
            headers: headers,
            body: encoded
        )
    }

    func patch<I: Encodable, O: Decodable & Sendable>(
        endpoint: String,
        params: [String: String]? = nil,
        headers: [String: String]? = nil,
        data: I,
        encoder: JSONEncoder = .init()
    ) async throws -> O {
        let encoded = try encoder.encode(data)
        return try await patch(
            endpoint: endpoint,
            params: params,
            headers: headers,
            body: encoded
        )
    }
}
