import Foundation
@testable import AppNetwork

@MainActor
final class URLProtocolStub: URLProtocol, @unchecked Sendable {
    static var stub: (data: Data?, response: URLResponse?, error: Error?)?
    static var lastRequest: URLRequest?
    static var requestBody: Data?

    static func configure(data: Data?, statusCode: Int) {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )
        configure(response: response, data: data, error: nil)
    }

    static func configure(response: URLResponse?, data: Data?, error: Error?) {
        stub = (data, response, error)
        lastRequest = nil
        requestBody = nil
    }

    static func configureError(_ error: Error) {
        configure(response: nil, data: nil, error: error)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Task { @MainActor in
            Self.lastRequest = request
        }

        if let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var data = Data()
            let bufferSize = 1 << 10
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate() }
            while stream.hasBytesAvailable {
                let read = stream.read(buffer, maxLength: bufferSize)
                if read <= 0 { break }
                data.append(buffer, count: read)
            }
            Task { @MainActor in
                Self.requestBody = data
            }
        } else {
            Task { @MainActor in
                Self.requestBody = request.httpBody
            }
        }

        Task { @MainActor in
            if let stub = Self.stub {
                if let response = stub.response {
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                }
                if let data = stub.data {
                    client?.urlProtocol(self, didLoad: data)
                }
                if let error = stub.error {
                    client?.urlProtocol(self, didFailWithError: error)
                } else {
                    client?.urlProtocolDidFinishLoading(self)
                }
            }
        }
    }

    override func stopLoading() {}
}
