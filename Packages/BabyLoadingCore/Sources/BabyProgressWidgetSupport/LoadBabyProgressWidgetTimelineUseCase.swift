import Foundation

public struct LoadBabyProgressWidgetTimelineUseCase:
    LoadBabyProgressWidgetTimelineUseCaseProtocol,
    Sendable {
    private static let futureDayCount = 7

    private let loadSnapshotUseCase: any LoadBabyProgressWidgetSnapshotUseCaseProtocol
    private let calendar: Calendar

    public init(
        loadSnapshotUseCase: any LoadBabyProgressWidgetSnapshotUseCaseProtocol,
        calendar: Calendar
    ) {
        self.loadSnapshotUseCase = loadSnapshotUseCase
        self.calendar = calendar
    }

    public func execute(asOf date: Date) async throws -> [BabyProgressWidgetSnapshot] {
        let currentSnapshot = try await loadSnapshotUseCase.execute(asOf: date)
        guard currentSnapshot.dueDate != nil else {
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

            snapshots.append(try await loadSnapshotUseCase.execute(asOf: scheduledDate))
        }

        return snapshots
    }
}

private enum WidgetTimelineSchedulingError: Error {
    case cannotCalculateScheduledDate
}
