import Foundation
import Testing
@testable import AppNetwork

@Suite("NetworkClient", .serialized)
struct NetworkClientTests: @unchecked Sendable {
    private struct MockDecodable: Codable, Equatable, Sendable {
        let value: String
    }

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private func makeSUT(baseUrl: String = "https://api.example.com") -> NetworkClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: config)
        return NetworkClient(baseUrl: baseUrl, session: session)
    }

    @Test("GET • happy path decodes JSON")
    func getSuccess() async throws {
        let sut = makeSUT()
        let expected = MockDecodable(value: "OK")
        await URLProtocolStub.configure(data: try encoder.encode(expected), statusCode: 200)

        let result: MockDecodable = try await sut.get(endpoint: "users/1")
        #expect(result == expected)
    }

    @Test("GET • query params are encoded and sent")
    func getEncodesQueryParams() async throws {
        let sut = makeSUT()
        let expected = MockDecodable(value: "OK")
        await URLProtocolStub.configure(data: try encoder.encode(expected), statusCode: 200)

        let _: MockDecodable = try await sut.get(
            endpoint: "users",
            params: ["page": "1", "query": "john doe"]
        )

        guard let url = await URLProtocolStub.lastRequest?.url else {
            return #expect(Bool(false), "Missing request URL")
        }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return #expect(Bool(false), "Missing URL components")
        }
        let queryItems = components.queryItems ?? []
        let map = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })
        #expect(map["page"] == "1")
        #expect(map["query"] == "john doe")
    }

    @Test("GET • malformed base URL maps to invalidURL")
    func malformedBaseURL() async {
        let baseURL = "http://[::1"
        let sut = makeSUT(baseUrl: baseURL)

        var thrown: Error?
        do {
            let _: MockDecodable = try await sut.get(endpoint: "users")
        } catch {
            thrown = error
        }

        if case let NetworkError.invalidURL(receivedBaseURL, path)? = thrown {
            #expect(receivedBaseURL == baseURL)
            #expect(path == "users")
        } else {
            #expect(Bool(false), "Expected invalidURL, got \(String(describing: thrown))")
        }
    }

    @Test("GET • non-HTTP response maps to nonHTTPResponse")
    func nonHTTPResponse() async {
        let sut = makeSUT()
        let response = URLResponse(
            url: URL(string: "https://example.com")!,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )
        await URLProtocolStub.configure(response: response, data: Data(), error: nil)

        var thrown: Error?
        do {
            let _: MockDecodable = try await sut.get(endpoint: "users")
        } catch {
            thrown = error
        }

        if case NetworkError.nonHTTPResponse? = thrown {
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "Expected nonHTTPResponse, got \(String(describing: thrown))")
        }
    }

    @Test("GET • transport errors are mapped")
    func transportError() async {
        let sut = makeSUT()
        await URLProtocolStub.configureError(URLError(.timedOut))

        var thrown: Error?
        do {
            let _: MockDecodable = try await sut.get(endpoint: "users")
        } catch {
            thrown = error
        }

        if case let NetworkError.transport(error)? = thrown {
            #expect(error.code == .timedOut)
        } else {
            #expect(Bool(false), "Expected transport error, got \(String(describing: thrown))")
        }
    }

    @Test("GET • 401 maps to unauthorized with body")
    func getUnauthorized() async {
        let sut = makeSUT()
        let payload = Data("{\"error\":\"auth\"}".utf8)
        await URLProtocolStub.configure(data: payload, statusCode: 401)

        var thrown: Error?
        do {
            let _: MockDecodable = try await sut.get(endpoint: "secure")
        } catch {
            thrown = error
        }

        if case let NetworkError.unauthorized(body)? = thrown {
            #expect(body == payload)
        } else {
            #expect(Bool(false), "Expected unauthorized, got \(String(describing: thrown))")
        }
    }

    @Test("GET • unexpected status maps to server error")
    func getUnexpectedStatus() async {
        let sut = makeSUT()
        let payload = Data("{\"error\":\"boom\"}".utf8)
        await URLProtocolStub.configure(data: payload, statusCode: 500)

        var thrown: Error?
        do {
            let _: MockDecodable = try await sut.get(endpoint: "boom")
        } catch {
            thrown = error
        }

        if case let NetworkError.server(statusCode, body)? = thrown {
            #expect(statusCode == 500)
            #expect(body == payload)
        } else {
            #expect(Bool(false), "Expected server error, got \(String(describing: thrown))")
        }
    }

    @Test("GET • empty successful body maps to emptyResponse")
    func emptyBodyOnSuccess() async {
        let sut = makeSUT()
        await URLProtocolStub.configure(data: Data(), statusCode: 200)

        var thrown: Error?
        do {
            let _: MockDecodable = try await sut.get(endpoint: "empty")
        } catch {
            thrown = error
        }

        if case NetworkError.emptyResponse? = thrown {
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "Expected emptyResponse, got \(String(describing: thrown))")
        }
    }

    @Test("GET • decoding failures include payload")
    func decodingFailure() async {
        let sut = makeSUT()
        let payload = Data("{\"wrong\":\"shape\"}".utf8)
        await URLProtocolStub.configure(data: payload, statusCode: 200)

        var thrown: Error?
        do {
            let _: MockDecodable = try await sut.get(endpoint: "decode")
        } catch {
            thrown = error
        }

        if case let NetworkError.decoding(description, body)? = thrown {
            #expect(!description.isEmpty)
            #expect(body == payload)
        } else {
            #expect(Bool(false), "Expected decoding error, got \(String(describing: thrown))")
        }
    }

    @Test("POST • happy path with body")
    func postSuccess() async throws {
        let sut = makeSUT()
        let expected = MockDecodable(value: "Created")
        await URLProtocolStub.configure(data: try encoder.encode(expected), statusCode: 200)

        let requestData = try encoder.encode(MockDecodable(value: "Request"))
        let result: MockDecodable = try await sut.post(endpoint: "items", body: requestData)
        #expect(result == expected)
    }

    @Test("POST • body is sent as-is")
    func postBodyCaptured() async throws {
        let sut = makeSUT()
        let expected = MockDecodable(value: "Echo")
        await URLProtocolStub.configure(data: try encoder.encode(expected), statusCode: 200)

        let requestValue = MockDecodable(value: "Body")
        let body = try encoder.encode(requestValue)
        let _: MockDecodable = try await sut.post(endpoint: "echo", body: body)

        guard let sent = await URLProtocolStub.requestBody else {
            return #expect(Bool(false), "No body captured")
        }
        let decoded = try decoder.decode(MockDecodable.self, from: sent)
        #expect(decoded == requestValue)
    }

    @Test("SEND • empty response can be explicitly represented")
    func emptyResponseType() async throws {
        let sut = makeSUT()
        await URLProtocolStub.configure(data: Data(), statusCode: 204)

        let request = NetworkRequest(method: .delete, path: "items/1")
        let _: EmptyResponse = try await sut.send(request)
        try await sut.send(request)
    }
}
