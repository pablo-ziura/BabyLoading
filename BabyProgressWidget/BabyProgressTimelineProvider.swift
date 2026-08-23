import AppLocalization
import Foundation
import OSLog
import PregnancyProgress
import WidgetKit

@MainActor
struct BabyProgressTimelineProvider: TimelineProvider {
    private static let logger = Logger(
        subsystem: "com.pablo.BabyLoading.widget",
        category: "PregnancyProgress"
    )

    private let repository: BabyProgressRepositoryProtocol
    private let loadPregnancyProgressUseCase: any LoadPregnancyProgressUseCaseProtocol
    private let language: AppLanguage

    init(
        repository: BabyProgressRepositoryProtocol,
        loadPregnancyProgressUseCase: any LoadPregnancyProgressUseCaseProtocol,
        language: AppLanguage
    ) {
        self.repository = repository
        self.loadPregnancyProgressUseCase = loadPregnancyProgressUseCase
        self.language = language
    }

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: .now,
            eventDate: .now,
            week: 40,
            babySize: .pumpkin,
            babySizeLabel: String(
                localized: "widget.placeholderPumpkinSize",
                defaultValue: "a pumpkin",
                locale: AppLanguage.english.locale
            ),
            languageCode: AppLanguage.english.rawValue
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        Task {
            completion(await makeEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        Task {
            let entry = await makeEntry()
            let nextUpdate = Date.now.addingTimeInterval(60 * 60)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

            completion(timeline)
        }
    }

    private func makeEntry() async -> SimpleEntry {
        let date = Date.now
        let progress: PregnancyProgress?

        do {
            progress = try await loadPregnancyProgressUseCase.execute(asOf: date)
        } catch {
            Self.logger.error(
                "Failed to load pregnancy progress: \(String(describing: error), privacy: .public)"
            )
            progress = nil
        }

        let week = progress?.currentWeek ?? 0
        let weekContent = repository.weekContent(for: week)

        return SimpleEntry(
            date: date,
            eventDate: progress?.dueDate,
            week: week,
            babySize: weekContent?.babySize ?? .unknown,
            babySizeLabel: weekContent?.babySizeLabel ?? String(
                localized: "widget.unknownSize",
                defaultValue: "a mystery",
                locale: language.locale
            ),
            languageCode: language.rawValue
        )
    }
}
