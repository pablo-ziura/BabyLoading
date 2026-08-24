import Foundation
import Observation
import PregnancyContent
import PregnancyProgress

public enum DashboardLoadingState: Equatable, Sendable {
    case idle
    case loaded
    case failed
}

@MainActor
@Observable
public final class DashboardViewModel {
    public private(set) var progress: PregnancyProgress?
    public private(set) var currentWeekContent: WeekContent?
    public private(set) var loadingState: DashboardLoadingState = .idle

    @ObservationIgnored private let loadPregnancyProgressUseCase: any LoadPregnancyProgressUseCaseProtocol
    @ObservationIgnored private var loadPregnancyWeekContentUseCase: any LoadPregnancyWeekContentUseCaseProtocol

    public init(
        loadPregnancyProgressUseCase: any LoadPregnancyProgressUseCaseProtocol,
        loadPregnancyWeekContentUseCase: any LoadPregnancyWeekContentUseCaseProtocol
    ) {
        self.loadPregnancyProgressUseCase = loadPregnancyProgressUseCase
        self.loadPregnancyWeekContentUseCase = loadPregnancyWeekContentUseCase
    }

    public func reload(asOf date: Date = .now) async {
        do {
            let loadedProgress = try await loadPregnancyProgressUseCase.execute(asOf: date)
            let loadedWeekContent: WeekContent?
            if let currentWeek = loadedProgress?.currentWeek {
                loadedWeekContent = await loadPregnancyWeekContentUseCase.execute(week: currentWeek)
            } else {
                loadedWeekContent = nil
            }

            progress = loadedProgress
            currentWeekContent = loadedWeekContent
            loadingState = .loaded
        } catch {
            loadingState = .failed
        }
    }

    public func reloadCurrentWeekContent(
        using loadPregnancyWeekContentUseCase: any LoadPregnancyWeekContentUseCaseProtocol
    ) async {
        self.loadPregnancyWeekContentUseCase = loadPregnancyWeekContentUseCase

        guard let currentWeek = progress?.currentWeek else {
            currentWeekContent = nil
            return
        }

        currentWeekContent = await loadPregnancyWeekContentUseCase.execute(week: currentWeek)
    }
}
