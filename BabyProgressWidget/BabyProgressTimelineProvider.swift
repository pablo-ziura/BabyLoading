import AppLocalization
import BabyProgressWidgetSupport
import Foundation
import OSLog
import WidgetKit

@MainActor
struct BabyProgressTimelineProvider: TimelineProvider {
    private static let logger = Logger(
        subsystem: "com.pablo.BabyLoading.widget",
        category: "PregnancyProgress"
    )

    private let loadSnapshotUseCase: any LoadBabyProgressWidgetSnapshotUseCaseProtocol
    private let language: AppLanguage

    init(
        loadSnapshotUseCase: any LoadBabyProgressWidgetSnapshotUseCaseProtocol,
        language: AppLanguage
    ) {
        self.loadSnapshotUseCase = loadSnapshotUseCase
        self.language = language
    }

    func placeholder(in context: Context) -> BabyProgressWidgetEntry {
        BabyProgressWidgetEntry(
            snapshot: BabyProgressWidgetSnapshot(
                date: .now,
                dueDate: .now,
                currentWeek: 40,
                babySizeImageName: "img_pumpkin",
                babySizeLabel: String(
                    localized: "widget.placeholderPumpkinSize",
                    defaultValue: "a pumpkin",
                    locale: AppLanguage.english.locale
                ),
                localeIdentifier: AppLanguage.english.rawValue
            )
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (BabyProgressWidgetEntry) -> Void
    ) {
        Task {
            completion(await makeEntry())
        }
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<BabyProgressWidgetEntry>) -> Void
    ) {
        Task {
            let entry = await makeEntry()
            let nextUpdate = Date.now.addingTimeInterval(60 * 60)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

            completion(timeline)
        }
    }

    private func makeEntry() async -> BabyProgressWidgetEntry {
        let date = Date.now

        do {
            return BabyProgressWidgetEntry(
                snapshot: try await loadSnapshotUseCase.execute(asOf: date)
            )
        } catch {
            Self.logger.error(
                "Failed to load widget snapshot: \(String(describing: error), privacy: .public)"
            )
        }

        return BabyProgressWidgetEntry(
            snapshot: BabyProgressWidgetSnapshot(
                date: date,
                dueDate: nil,
                currentWeek: 0,
                babySizeImageName: "img_unknown",
                babySizeLabel: nil,
                localeIdentifier: language.rawValue
            )
        )
    }
}
