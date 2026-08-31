import AppLocalization
import PregnancyContent
import PregnancyProgress

public struct LoadBabyProgressWidgetContextUseCase:
    LoadBabyProgressWidgetContextUseCaseProtocol,
    Sendable {
    private let loadLastPeriodDateUseCase: any LoadLastPeriodDateUseCaseProtocol
    private let loadPregnancyTimelineUseCase: any LoadPregnancyTimelineUseCaseProtocol
    private let language: AppLanguage

    public init(
        loadLastPeriodDateUseCase: any LoadLastPeriodDateUseCaseProtocol,
        loadPregnancyTimelineUseCase: any LoadPregnancyTimelineUseCaseProtocol,
        language: AppLanguage
    ) {
        self.loadLastPeriodDateUseCase = loadLastPeriodDateUseCase
        self.loadPregnancyTimelineUseCase = loadPregnancyTimelineUseCase
        self.language = language
    }

    public func execute() async throws -> BabyProgressWidgetContext {
        async let lastPeriodDate = loadLastPeriodDateUseCase.execute()
        async let weeklyContent = loadPregnancyTimelineUseCase.execute()
        let contextValues = try await (lastPeriodDate, weeklyContent)

        return BabyProgressWidgetContext(
            lastPeriodDate: contextValues.0,
            weeklyContent: contextValues.1,
            language: language
        )
    }
}
