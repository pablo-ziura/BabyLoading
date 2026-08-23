@testable import BabyLoading
import Foundation

final class MockPregnancyContentRepository: PregnancyContentRepositoryProtocol {
    var snapshot = PregnancyContentDocument.empty

    func currentSnapshot() -> PregnancyContentDocument {
        snapshot
    }

    func weekContent(for week: Int) -> WeekContent? {
        guard week >= 6 else { return nil }
        let clampedWeek = min(week, 40)
        return snapshot.weeks.first(where: { $0.week == clampedWeek })
    }

    func allWeekContent() -> [WeekContent] {
        snapshot.weeks
    }
}
