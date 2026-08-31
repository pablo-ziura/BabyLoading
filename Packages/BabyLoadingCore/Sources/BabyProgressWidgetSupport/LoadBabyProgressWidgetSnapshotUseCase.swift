import Foundation

public struct LoadBabyProgressWidgetSnapshotUseCase:
    LoadBabyProgressWidgetSnapshotUseCaseProtocol,
    Sendable {
    private let loadContextUseCase: any LoadBabyProgressWidgetContextUseCaseProtocol
    private let snapshotFactory: any BabyProgressWidgetSnapshotFactoryProtocol

    public init(
        loadContextUseCase: any LoadBabyProgressWidgetContextUseCaseProtocol,
        snapshotFactory: any BabyProgressWidgetSnapshotFactoryProtocol
    ) {
        self.loadContextUseCase = loadContextUseCase
        self.snapshotFactory = snapshotFactory
    }

    public func execute(asOf date: Date) async throws -> BabyProgressWidgetSnapshot {
        let context = try await loadContextUseCase.execute()
        return snapshotFactory.makeSnapshot(from: context, asOf: date)
    }
}
