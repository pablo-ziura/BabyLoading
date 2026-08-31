import AppLocalization
import BabyProgressWidgetSupport
import Foundation
import PregnancyContent
import PregnancyProgress

actor PregnancyProgressRepositoryRecorder: PregnancyProgressRepositoryProtocol {
    private let lastPeriodDate: Date?
    private(set) var loadCallCount = 0

    init(lastPeriodDate: Date?) {
        self.lastPeriodDate = lastPeriodDate
    }

    func loadLastPeriodDate() -> Date? {
        loadCallCount += 1
        return lastPeriodDate
    }

    func updateLastPeriodDate(_ date: Date?) {}
}

actor PregnancyTimelineContentUseCaseRecorder: LoadPregnancyTimelineUseCaseProtocol {
    private let content: [WeekContent]
    private(set) var executionCount = 0

    init(content: [WeekContent]) {
        self.content = content
    }

    func execute() -> [WeekContent] {
        executionCount += 1
        return content
    }
}

struct WidgetContextUseCaseStub: LoadBabyProgressWidgetContextUseCaseProtocol {
    let context: BabyProgressWidgetContext

    func execute() async throws -> BabyProgressWidgetContext {
        context
    }
}

actor WidgetContextUseCaseRecorder: LoadBabyProgressWidgetContextUseCaseProtocol {
    private let context: BabyProgressWidgetContext
    private(set) var executionCount = 0

    init(context: BabyProgressWidgetContext) {
        self.context = context
    }

    func execute() -> BabyProgressWidgetContext {
        executionCount += 1
        return context
    }
}

struct FailingWidgetContextUseCaseStub: LoadBabyProgressWidgetContextUseCaseProtocol {
    func execute() async throws -> BabyProgressWidgetContext {
        throw WidgetSnapshotTestError.loadFailed
    }
}

enum WidgetSnapshotTestError: Error {
    case loadFailed
}
