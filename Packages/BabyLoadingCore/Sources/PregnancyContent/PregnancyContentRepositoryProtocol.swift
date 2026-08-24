import Foundation

public protocol PregnancyContentRepositoryProtocol: Sendable {
    func currentSnapshot() async -> PregnancyContentDocument
    func weekContent(for week: Int) async -> WeekContent?
    func allWeekContent() async -> [WeekContent]
}
