@testable import BabyLoading
import XCTest

final class PregnancyContentRepositoryTests: XCTestCase {
    func testCurrentSnapshot_PrefersBundleOverLegacyCache() {
        let bundledDocument = makeDocument(revision: 1)
        let cachedDocument = makeDocument(revision: 3)
        let repository = PregnancyContentRepository(
            expectedLocale: "en",
            bundleSource: MockBundleSource(document: bundledDocument),
            cacheStore: MockCacheStore(document: cachedDocument)
        )

        XCTAssertEqual(repository.currentSnapshot(), bundledDocument)
    }

    func testCurrentSnapshot_UsesLegacyCacheWhenBundleIsMissing() {
        let cachedDocument = makeDocument(revision: 3)
        let repository = PregnancyContentRepository(
            expectedLocale: "en",
            bundleSource: MockBundleSource(document: nil),
            cacheStore: MockCacheStore(document: cachedDocument)
        )

        XCTAssertEqual(repository.currentSnapshot(), cachedDocument)
    }

    func testCurrentSnapshot_UsesEmptyDocumentWhenSourcesAreMissing() {
        let repository = PregnancyContentRepository(
            expectedLocale: "es",
            bundleSource: MockBundleSource(document: nil),
            cacheStore: MockCacheStore(document: nil)
        )

        XCTAssertEqual(repository.currentSnapshot(), .empty(locale: "es"))
    }

    func testWeekContent_ClampsWeeksAfterPregnancyAndRejectsEarlierWeeks() {
        let document = makeDocument(revision: 1)
        let repository = PregnancyContentRepository(
            expectedLocale: "en",
            bundleSource: MockBundleSource(document: document),
            cacheStore: MockCacheStore(document: nil)
        )

        XCTAssertNil(repository.weekContent(for: 5))
        XCTAssertEqual(repository.weekContent(for: 41), document.weeks.last)
    }

    private func makeDocument(revision: Int) -> PregnancyContentDocument {
        let sizes = BabySize.allCases.filter { $0 != .unknown }
        let weeks = PregnancyContentDocument.coveredWeeks.enumerated().map { index, week in
            WeekContent(
                week: week,
                babySize: sizes[index],
                babySizeLabel: "Size \(week)",
                milestoneTitle: "Week \(week)",
                keyEvents: ["Event \(week)"],
                physiologicalImpact: "Impact \(week)"
            )
        }

        return PregnancyContentDocument(
            schemaVersion: 1,
            locale: "en",
            revision: revision,
            weeks: weeks
        )
    }
}

private struct MockBundleSource: PregnancyContentBundleSourceProtocol {
    let document: PregnancyContentDocument?

    func loadDocument() -> PregnancyContentDocument? {
        document
    }
}

private final class MockCacheStore: PregnancyContentCacheStoreProtocol {
    let document: PregnancyContentDocument?

    init(document: PregnancyContentDocument?) {
        self.document = document
    }

    func loadDocument() -> PregnancyContentDocument? {
        document
    }
}
