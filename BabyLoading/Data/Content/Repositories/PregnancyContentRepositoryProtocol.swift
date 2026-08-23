import Foundation

protocol PregnancyContentRepositoryProtocol {
    func currentSnapshot() -> PregnancyContentDocument
    func weekContent(for week: Int) -> WeekContent?
    func allWeekContent() -> [WeekContent]
}
