import Foundation

public struct LoadBabyProgressWidgetTimelineUseCase:
    LoadBabyProgressWidgetTimelineUseCaseProtocol,
    Sendable {
    private static let futureDayCount = 7

    private let loadContextUseCase: any LoadBabyProgressWidgetContextUseCaseProtocol
    private let snapshotFactory: any BabyProgressWidgetSnapshotFactoryProtocol
    private let calendar: Calendar

    public init(
        loadContextUseCase: any LoadBabyProgressWidgetContextUseCaseProtocol,
        snapshotFactory: any BabyProgressWidgetSnapshotFactoryProtocol,
        calendar: Calendar
    ) {
        self.loadContextUseCase = loadContextUseCase
        self.snapshotFactory = snapshotFactory
        self.calendar = calendar
    }

    public func execute(asOf date: Date) async throws -> [BabyProgressWidgetSnapshot] {
        let context = try await loadContextUseCase.execute()
        let currentSnapshot = snapshotFactory.makeSnapshot(from: context, asOf: date)
        guard currentSnapshot.requiresDailyTimelineRefresh else {
            return [currentSnapshot]
        }

        let startOfCurrentDay = calendar.startOfDay(for: date)
        var snapshots = [currentSnapshot]

        for dayOffset in 1 ... Self.futureDayCount {
            guard let scheduledDate = calendar.date(
                byAdding: .day,
                value: dayOffset,
                to: startOfCurrentDay
            ) else {
                throw WidgetTimelineSchedulingError.cannotCalculateScheduledDate
            }

            snapshots.append(snapshotFactory.makeSnapshot(from: context, asOf: scheduledDate))
        }

        return snapshots
    }
}

private enum WidgetTimelineSchedulingError: Error {
    case cannotCalculateScheduledDate
}
