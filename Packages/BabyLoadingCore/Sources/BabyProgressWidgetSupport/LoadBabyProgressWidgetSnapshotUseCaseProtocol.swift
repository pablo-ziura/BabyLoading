import Foundation

public protocol LoadBabyProgressWidgetSnapshotUseCaseProtocol: Sendable {
    func execute(asOf date: Date) async throws -> BabyProgressWidgetSnapshot
}
