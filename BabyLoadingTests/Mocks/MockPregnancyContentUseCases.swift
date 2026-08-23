import PregnancyContent

@MainActor
final class MockLoadPregnancyWeekContentUseCase: LoadPregnancyWeekContentUseCaseProtocol {
    var result: WeekContent?
    private(set) var executeCallCount = 0
    private(set) var requestedWeek: Int?

    func execute(week: Int) async -> WeekContent? {
        executeCallCount += 1
        requestedWeek = week
        return result
    }
}

@MainActor
final class MockLoadPregnancyTimelineUseCase: LoadPregnancyTimelineUseCaseProtocol {
    var result: [WeekContent] = []
    private(set) var executeCallCount = 0

    func execute() async -> [WeekContent] {
        executeCallCount += 1
        return result
    }
}
