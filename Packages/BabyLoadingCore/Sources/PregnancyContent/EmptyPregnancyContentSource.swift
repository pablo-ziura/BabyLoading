import Foundation

public struct EmptyPregnancyContentSource: PregnancyContentSourceProtocol, Sendable {
    public init() {}

    public func loadDocument() async throws -> PregnancyContentDocument? {
        nil
    }
}
