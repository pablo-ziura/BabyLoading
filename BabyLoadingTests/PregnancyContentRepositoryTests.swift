@testable import BabyLoading
import XCTest

final class PregnancyContentRepositoryTests: XCTestCase {
    func testCurrentSnapshot_UsesBundleWhenCacheIsMissing() {
        let bundleDocument = makeDocument(revision: 1)
        let cacheStore = MockCacheStore(document: nil)
        let repository = PregnancyContentRepository(
            expectedLocale: "en",
            bundleSource: MockBundleSource(document: bundleDocument),
            cacheStore: cacheStore,
            remoteSource: MockRemoteSource()
        )

        XCTAssertEqual(repository.currentSnapshot(), bundleDocument)
        XCTAssertNil(cacheStore.revision)
    }

    func testCurrentSnapshot_PrefersCacheOverBundle() {
        let cachedDocument = makeDocument(revision: 3)
        let repository = PregnancyContentRepository(
            expectedLocale: "en",
            bundleSource: MockBundleSource(document: makeDocument(revision: 1)),
            cacheStore: MockCacheStore(document: cachedDocument),
            remoteSource: MockRemoteSource()
        )

        XCTAssertEqual(repository.currentSnapshot(), cachedDocument)
    }

    func testRefreshIfNeeded_DoesNotOverwriteCacheOnNotModified() async {
        let cachedDocument = makeDocument(revision: 2)
        let cacheStore = MockCacheStore(document: cachedDocument)
        cacheStore.eTag = "etag-1"
        let remoteSource = MockRemoteSource(result: .success(.notModified))
        let expectedDate = Date(timeIntervalSince1970: 1234)
        let repository = PregnancyContentRepository(
            expectedLocale: "en",
            bundleSource: MockBundleSource(document: makeDocument(revision: 1)),
            cacheStore: cacheStore,
            remoteSource: remoteSource,
            refreshInterval: 0,
            now: { expectedDate }
        )

        await repository.refreshIfNeeded()

        XCTAssertEqual(repository.currentSnapshot(), cachedDocument)
        XCTAssertTrue(cacheStore.savedDocuments.isEmpty)
        XCTAssertEqual(cacheStore.lastFetchAt, expectedDate)
        XCTAssertEqual(remoteSource.receivedETag, "etag-1")
    }

    func testRefreshIfNeeded_ReplacesCacheWhenRevisionIsNewer() async {
        let cachedDocument = makeDocument(revision: 1)
        let updatedDocument = makeDocument(revision: 2)
        let cacheStore = MockCacheStore(document: cachedDocument)
        cacheStore.revision = 1
        let repository = PregnancyContentRepository(
            expectedLocale: "en",
            bundleSource: MockBundleSource(document: cachedDocument),
            cacheStore: cacheStore,
            remoteSource: MockRemoteSource(
                result: .success(.success(document: updatedDocument, eTag: "etag-2"))
            ),
            refreshInterval: 0,
            now: { Date(timeIntervalSince1970: 5678) }
        )

        await repository.refreshIfNeeded()

        XCTAssertEqual(repository.currentSnapshot(), updatedDocument)
        XCTAssertEqual(cacheStore.document, updatedDocument)
        XCTAssertEqual(cacheStore.revision, 2)
        XCTAssertEqual(cacheStore.eTag, "etag-2")
        XCTAssertEqual(cacheStore.savedDocuments, [updatedDocument])
    }

    func testRefreshIfNeeded_IgnoresRemoteDocumentWithSameRevision() async {
        let cachedDocument = makeDocument(revision: 2)
        let cacheStore = MockCacheStore(document: cachedDocument)
        cacheStore.revision = 2
        let repository = PregnancyContentRepository(
            expectedLocale: "en",
            bundleSource: MockBundleSource(document: makeDocument(revision: 1)),
            cacheStore: cacheStore,
            remoteSource: MockRemoteSource(
                result: .success(.success(document: makeDocument(revision: 2), eTag: "etag-2"))
            ),
            refreshInterval: 0
        )

        await repository.refreshIfNeeded()

        XCTAssertEqual(repository.currentSnapshot(), cachedDocument)
        XCTAssertTrue(cacheStore.savedDocuments.isEmpty)
        XCTAssertEqual(cacheStore.revision, 2)
    }

    func testRefreshIfNeeded_IgnoresInvalidRemoteDocumentAndKeepsCache() async {
        let cachedDocument = makeDocument(revision: 2)
        let invalidDocument = PregnancyContentDocument(
            schemaVersion: 1,
            locale: "en",
            revision: 3,
            weeks: Array(makeDocument(revision: 3).weeks.prefix(2))
        )
        let cacheStore = MockCacheStore(document: cachedDocument)
        cacheStore.revision = 2
        let repository = PregnancyContentRepository(
            expectedLocale: "en",
            bundleSource: MockBundleSource(document: makeDocument(revision: 1)),
            cacheStore: cacheStore,
            remoteSource: MockRemoteSource(
                result: .success(.success(document: invalidDocument, eTag: "etag-3"))
            ),
            refreshInterval: 0
        )

        await repository.refreshIfNeeded()

        XCTAssertEqual(repository.currentSnapshot(), cachedDocument)
        XCTAssertTrue(cacheStore.savedDocuments.isEmpty)
        XCTAssertEqual(cacheStore.revision, 2)
    }

    func testRefreshIfNeeded_DoesNotAdvanceStateWhenPersistingNewDocumentFails() async {
        let cachedDocument = makeDocument(revision: 1)
        let updatedDocument = makeDocument(revision: 2)
        let cacheStore = MockCacheStore(document: cachedDocument, saveResult: false)
        cacheStore.revision = 1
        cacheStore.eTag = "etag-1"
        let repository = PregnancyContentRepository(
            expectedLocale: "en",
            bundleSource: MockBundleSource(document: cachedDocument),
            cacheStore: cacheStore,
            remoteSource: MockRemoteSource(
                result: .success(.success(document: updatedDocument, eTag: "etag-2"))
            ),
            refreshInterval: 0,
            now: { Date(timeIntervalSince1970: 9999) }
        )

        await repository.refreshIfNeeded()

        XCTAssertEqual(repository.currentSnapshot(), cachedDocument)
        XCTAssertEqual(cacheStore.document, cachedDocument)
        XCTAssertEqual(cacheStore.revision, 1)
        XCTAssertEqual(cacheStore.eTag, "etag-1")
        XCTAssertNil(cacheStore.lastFetchAt)
        XCTAssertTrue(cacheStore.savedDocuments.isEmpty)
    }

    private func makeDocument(revision: Int) -> PregnancyContentDocument {
        let sizes = BabySize.allCases.filter { $0 != .unknown }
        let weeks = PregnancyContentDocument.coveredWeeks.enumerated().map { index, week in
            WeekContent(
                week: week,
                babySize: sizes[index],
                babySizeLabel: "Tamaño \(week)",
                milestoneTitle: "Semana \(week)",
                keyEvents: ["Evento \(week)"],
                physiologicalImpact: "Impacto \(week)"
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
    var document: PregnancyContentDocument?
    var savedDocuments: [PregnancyContentDocument] = []
    var eTag: String?
    var lastFetchAt: Date?
    var revision: Int?
    private let saveResult: Bool

    init(document: PregnancyContentDocument?, saveResult: Bool = true) {
        self.document = document
        self.saveResult = saveResult
    }

    func loadDocument() -> PregnancyContentDocument? {
        document
    }

    @discardableResult
    func saveDocument(_ document: PregnancyContentDocument) -> Bool {
        guard saveResult else {
            return false
        }

        self.document = document
        savedDocuments.append(document)
        return true
    }
}

private final class MockRemoteSource: PregnancyContentRemoteSourceProtocol {
    var isEnabled = true
    var receivedETag: String?

    private let result: Result<PregnancyContentRemoteFetchResult, Error>

    init(result: Result<PregnancyContentRemoteFetchResult, Error> = .failure(PregnancyContentRemoteSourceError.missingURL)) {
        self.result = result
    }

    func fetch(ifNoneMatch eTag: String?) async throws -> PregnancyContentRemoteFetchResult {
        receivedETag = eTag
        return try result.get()
    }
}
