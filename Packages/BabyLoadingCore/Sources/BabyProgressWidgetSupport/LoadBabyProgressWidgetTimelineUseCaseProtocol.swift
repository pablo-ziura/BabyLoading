import Foundation

public protocol LoadBabyProgressWidgetTimelineUseCaseProtocol: Sendable {
    func execute(asOf date: Date) async throws -> [BabyProgressWidgetSnapshot]
}
