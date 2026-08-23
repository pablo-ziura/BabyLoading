import Foundation

final class PregnancyContentRepository: PregnancyContentRepositoryProtocol {
    private let expectedLocale: String
    private let bundleSource: PregnancyContentBundleSourceProtocol
    private let cacheStore: PregnancyContentCacheStoreProtocol
    private let remoteSource: PregnancyContentRemoteSourceProtocol
    private let refreshInterval: TimeInterval
    private let now: () -> Date

    private var snapshot: PregnancyContentDocument

    init(
        expectedLocale: String = PregnancyContentLocalization.fallbackLocale,
        bundleSource: PregnancyContentBundleSourceProtocol,
        cacheStore: PregnancyContentCacheStoreProtocol,
        remoteSource: PregnancyContentRemoteSourceProtocol,
        refreshInterval: TimeInterval = 60 * 60 * 12,
        now: @escaping () -> Date = Date.init
    ) {
        self.expectedLocale = expectedLocale
        self.bundleSource = bundleSource
        self.cacheStore = cacheStore
        self.remoteSource = remoteSource
        self.refreshInterval = refreshInterval
        self.now = now

        if let cachedSnapshot = cacheStore.loadDocument() {
            snapshot = cachedSnapshot
            cacheStore.revision = cachedSnapshot.revision
        } else if let bundledSnapshot = bundleSource.loadDocument() {
            snapshot = bundledSnapshot
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

    func refreshIfNeeded() async {
        guard remoteSource.isEnabled else {
            return
        }

        let fetchDate = now()

        if let lastFetchAt = cacheStore.lastFetchAt,
           fetchDate.timeIntervalSince(lastFetchAt) < refreshInterval {
            return
        }

        do {
            let result = try await remoteSource.fetch(ifNoneMatch: cacheStore.eTag)

            switch result {
            case .notModified:
                cacheStore.lastFetchAt = fetchDate

            case let .success(document, eTag):
                let validatedDocument = try document.validated(
                    expectedLocale: expectedLocale,
                    minimumRevision: cacheStore.revision
                )
                guard cacheStore.saveDocument(validatedDocument) else {
                    return
                }

                snapshot = validatedDocument
                cacheStore.eTag = eTag
                cacheStore.lastFetchAt = fetchDate
                cacheStore.revision = validatedDocument.revision
            }
        } catch {
            return
        }
    }
}
