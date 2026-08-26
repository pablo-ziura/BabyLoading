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
    private let loadTimelineUseCase: any LoadBabyProgressWidgetTimelineUseCaseProtocol
    private let language: AppLanguage

    init(
        loadSnapshotUseCase: any LoadBabyProgressWidgetSnapshotUseCaseProtocol,
        loadTimelineUseCase: any LoadBabyProgressWidgetTimelineUseCaseProtocol,
        language: AppLanguage
    ) {
        self.loadSnapshotUseCase = loadSnapshotUseCase
        self.loadTimelineUseCase = loadTimelineUseCase
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
            let date = Date.now

            do {
                let snapshots = try await loadTimelineUseCase.execute(asOf: date)
                let entries = snapshots.map(BabyProgressWidgetEntry.init(snapshot:))
                let policy: TimelineReloadPolicy = entries.count > 1 ? .atEnd : .never

                completion(Timeline(entries: entries, policy: policy))
            } catch {
                Self.logger.error(
                    "Failed to load widget timeline: \(String(describing: error), privacy: .public)"
                )
                let retryDate = date.addingTimeInterval(60 * 60)
                let timeline = Timeline(
                    entries: [makeFallbackEntry(date: date)],
                    policy: .after(retryDate)
                )

                completion(timeline)
            }
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

        return makeFallbackEntry(date: date)
    }

    private func makeFallbackEntry(date: Date) -> BabyProgressWidgetEntry {
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
