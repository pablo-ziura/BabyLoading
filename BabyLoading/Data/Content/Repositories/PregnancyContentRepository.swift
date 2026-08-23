import Foundation

final class PregnancyContentRepository: PregnancyContentRepositoryProtocol {
    private var snapshot: PregnancyContentDocument

    init(
        expectedLocale: String = PregnancyContentLocalization.fallbackLocale,
        bundleSource: PregnancyContentBundleSourceProtocol,
        cacheStore: PregnancyContentCacheStoreProtocol
    ) {
        if let bundledSnapshot = bundleSource.loadDocument() {
            snapshot = bundledSnapshot
        } else if let cachedSnapshot = cacheStore.loadDocument() {
            snapshot = cachedSnapshot
        } else {
            snapshot = .empty(locale: expectedLocale)
        }
    }

    func currentSnapshot() -> PregnancyContentDocument {
        snapshot
    }

    func weekContent(for week: Int) -> WeekContent? {
        guard week >= PregnancyContentDocument.coveredWeeks.first ?? 6 else {
            return nil
        }

        let clampedWeek = min(week, PregnancyContentDocument.coveredWeeks.last ?? 40)
        return snapshot.weeks.first(where: { $0.week == clampedWeek })
    }

    func allWeekContent() -> [WeekContent] {
        snapshot.weeks
    }
}
