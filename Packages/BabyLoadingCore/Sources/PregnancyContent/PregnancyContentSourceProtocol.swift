import Foundation

public protocol PregnancyContentSourceProtocol: Sendable {
    func loadDocument() async throws -> PregnancyContentDocument?
}
