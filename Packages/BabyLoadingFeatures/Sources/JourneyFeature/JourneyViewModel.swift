import Foundation
import Observation
import PregnancyContent
import PregnancyProgress

public enum JourneyLoadingState: Equatable, Sendable {
    case idle
    case loaded
    case failed
}

@MainActor
@Observable
public final class JourneyViewModel {
    public private(set) var progress: PregnancyProgress?
    public private(set) var pregnancyTimeline: [WeekContent] = []
    public private(set) var loadingState: JourneyLoadingState = .idle

    @ObservationIgnored private let loadPregnancyProgressUseCase: any LoadPregnancyProgressUseCaseProtocol
    @ObservationIgnored private var loadPregnancyTimelineUseCase: any LoadPregnancyTimelineUseCaseProtocol

    public init(
        loadPregnancyProgressUseCase: any LoadPregnancyProgressUseCaseProtocol,
        loadPregnancyTimelineUseCase: any LoadPregnancyTimelineUseCaseProtocol
    ) {
        self.loadPregnancyProgressUseCase = loadPregnancyProgressUseCase
        self.loadPregnancyTimelineUseCase = loadPregnancyTimelineUseCase
    }

    public func reload(asOf date: Date = .now) async {
        let loadedWeekContent = await loadPregnancyTimelineUseCase.execute()

        do {
            let loadedProgress = try await loadPregnancyProgressUseCase.execute(asOf: date)
            pregnancyTimeline = loadedWeekContent
            progress = loadedProgress
            loadingState = .loaded
        } catch {
            if !loadedWeekContent.isEmpty {
                pregnancyTimeline = loadedWeekContent
            }
            loadingState = .failed
        }
    }

    public func reloadTimeline(
        using loadPregnancyTimelineUseCase: any LoadPregnancyTimelineUseCaseProtocol
    ) async {
        self.loadPregnancyTimelineUseCase = loadPregnancyTimelineUseCase
        pregnancyTimeline = await loadPregnancyTimelineUseCase.execute()
    }

    public func currentDayOffset(asOf date: Date = .now, calendar: Calendar = .current) -> Int {
        guard let lastPeriodDate = progress?.lastPeriodDate else {
            return 0
        }

        let startDate = calendar.startOfDay(for: lastPeriodDate)
        let currentDate = calendar.startOfDay(for: date)
        let elapsedDays = calendar.dateComponents([.day], from: startDate, to: currentDate).day ?? 0
        return max(0, elapsedDays) % 7
    }
}
