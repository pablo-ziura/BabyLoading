import Foundation

public protocol LoadPregnancyProgressUseCaseProtocol: Sendable {
    func execute(asOf date: Date) async throws -> PregnancyProgress?
}
