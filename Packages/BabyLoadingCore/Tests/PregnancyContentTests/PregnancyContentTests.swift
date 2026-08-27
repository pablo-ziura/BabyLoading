import Foundation
@testable import PregnancyContent
import Testing

struct PregnancyContentTests {
    @Test func documentValidationPreservesSchemaAndCompleteCoverage() throws {
        let document = makeDocument(locale: "en", revision: 4)
        let data = try JSONEncoder().encode(document)

        let decodedDocument = try PregnancyContentDocument.decodeValidated(
            from: data,
            expectedLocale: "en"
        )

        #expect(PregnancyContentDocument.supportedSchemaVersion == 1)
        #expect(decodedDocument.weeks.map(\.week) == Array(6 ... 40))
    }

    @Test func documentValidationRejectsUnsupportedSchemaVersion() throws {
        let validDocument = makeDocument(locale: "en", revision: 1)
        let document = PregnancyContentDocument(
            schemaVersion: 2,
            locale: validDocument.locale,
            revision: validDocument.revision,
            weeks: validDocument.weeks
        )

        #expect(throws: PregnancyContentValidationError.unsupportedSchemaVersion(2)) {
            try decode(document, expectedLocale: "en")
        }
    }

    @Test func documentValidationRejectsDuplicateWeeks() throws {
        var weeks = makeDocument(locale: "en", revision: 1).weeks
        weeks[1] = weeks[0]
        let document = PregnancyContentDocument(
            schemaVersion: 1,
            locale: "en",
            revision: 1,
            weeks: weeks
        )

        #expect(throws: PregnancyContentValidationError.duplicateWeeks([6])) {
            try decode(document, expectedLocale: "en")
        }
    }

    @Test func documentValidationRejectsIncompleteWeekCoverage() throws {
        let weeks = Array(makeDocument(locale: "en", revision: 1).weeks.prefix(2))
        let document = PregnancyContentDocument(
            schemaVersion: 1,
            locale: "en",
            revision: 1,
            weeks: weeks
        )

        #expect(throws: PregnancyContentValidationError.invalidWeekCoverage([6, 7])) {
            try decode(document, expectedLocale: "en")
        }
    }

    @Test func documentValidationRejectsUnexpectedLocale() throws {
        let document = makeDocument(locale: "es", revision: 1)

        #expect(throws: PregnancyContentValidationError.unsupportedLocale("es")) {
            try decode(document, expectedLocale: "en")
        }
    }

    @Test func documentValidationRejectsEmptyKeyEvents() throws {
        let validDocument = makeDocument(locale: "en", revision: 1)
        var weeks = validDocument.weeks
        let firstWeek = weeks[0]
        weeks[0] = WeekContent(
            week: firstWeek.week,
            babySize: firstWeek.babySize,
            babySizeLabel: firstWeek.babySizeLabel,
            milestoneTitle: firstWeek.milestoneTitle,
            keyEvents: ["   "],
            physiologicalImpact: firstWeek.physiologicalImpact
        )
        let document = PregnancyContentDocument(
            schemaVersion: validDocument.schemaVersion,
            locale: validDocument.locale,
            revision: validDocument.revision,
            weeks: weeks
        )

        #expect(throws: PregnancyContentValidationError.emptyKeyEvents(week: firstWeek.week)) {
            try decode(document, expectedLocale: "en")
        }
    }

    @Test func documentDecodingRejectsUnknownBabySize() {
        let data = Data(
            """
            {
              "schemaVersion": 1,
              "locale": "en",
              "revision": 1,
              "weeks": [
                {
                  "week": 6,
                  "babySize": "dragonEgg",
                  "babySizeLabel": "a dragon egg",
                  "milestoneTitle": "Week 6",
                  "keyEvents": ["Event"],
                  "physiologicalImpact": null
                }
              ]
            }
            """.utf8
        )

        #expect(throws: DecodingError.self) {
            try PregnancyContentDocument.decodeValidated(from: data, expectedLocale: "en")
        }
    }

    @Test func localeResolutionUsesSupportedPreferredLanguage() {
        let localization = PregnancyContentLocalization.resolve(
            supportedLocales: ["en", "es"],
            preferredLanguages: ["es-ES"]
        )

        #expect(localization.localeCode == "es")
        #expect(localization.resourceName == "pregnancy-content.es")
        #expect(localization.fileName == "pregnancy-content.es.json")
    }

    @Test func localeResolutionFallsBackToEnglishForUnsupportedLanguage() {
        let localization = PregnancyContentLocalization.resolve(
            supportedLocales: ["en", "es"],
            preferredLanguages: ["fr-FR"]
        )

        #expect(localization.localeCode == "en")
    }

    @Test func localeResolutionHonorsHostBundlePreferenceOrder() {
        let localization = PregnancyContentLocalization.resolve(
            supportedLocales: ["en", "es"],
            preferredLanguages: ["es", "fr-FR"]
        )

        #expect(localization.localeCode == "es")
    }

    @Test func legacyCacheFileNamesRemainSeparatedByLocale() {
        let englishLocalization = PregnancyContentLocalization(localeCode: "en")
        let spanishLocalization = PregnancyContentLocalization(localeCode: "es")

        #expect(englishLocalization.fileName == "pregnancy-content.en.json")
        #expect(spanishLocalization.fileName == "pregnancy-content.es.json")
        #expect(englishLocalization.fileName != spanishLocalization.fileName)
    }

    @Test func bundleDocumentTakesPriorityOverNewerLegacyCache() async {
        let bundleDocument = makeDocument(locale: "en", revision: 1)
        let legacyDocument = makeDocument(locale: "en", revision: 9)
        let repository = PregnancyContentRepository(
            expectedLocale: "en",
            bundleSource: PregnancyContentSourceStub(result: .document(bundleDocument)),
            legacyCacheSource: PregnancyContentSourceStub(result: .document(legacyDocument))
        )

        let snapshot = await repository.currentSnapshot()

        #expect(snapshot == bundleDocument)
    }

    @Test func invalidBundleFallsBackToReadOnlyLegacyCache() async {
        let legacyDocument = makeDocument(locale: "es", revision: 8)
        let repository = PregnancyContentRepository(
            expectedLocale: "es",
            bundleSource: PregnancyContentSourceStub(result: .failure),
            legacyCacheSource: PregnancyContentSourceStub(result: .document(legacyDocument))
        )

        let snapshot = await repository.currentSnapshot()

        #expect(snapshot == legacyDocument)
    }

    @Test func missingSourcesProduceLocaleSpecificEmptyDocument() async {
        let repository = PregnancyContentRepository(
            expectedLocale: "es",
            bundleSource: EmptyPregnancyContentSource(),
            legacyCacheSource: EmptyPregnancyContentSource()
        )

        let snapshot = await repository.currentSnapshot()

        #expect(snapshot == .empty(locale: "es"))
    }

    @Test func legacyCacheUsesHistoricalRootFileName() async throws {
        let fileManager = FileManager.default
        let containerURL = fileManager.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        try fileManager.createDirectory(at: containerURL, withIntermediateDirectories: true)
        defer {
            do {
                try fileManager.removeItem(at: containerURL)
            } catch {
                Issue.record(error)
            }
        }
        let localization = PregnancyContentLocalization(localeCode: "en")
        let expectedDocument = makeDocument(locale: "en", revision: 7)
        let cacheURL = containerURL.appendingPathComponent("pregnancy-content.en.json")
        try JSONEncoder().encode(expectedDocument).write(to: cacheURL, options: .atomic)
        let store = LegacyPregnancyContentCacheStore(
            localization: localization,
            containerURL: containerURL
        )

        let loadedDocument = try await store.loadDocument()

        #expect(localization.fileName == "pregnancy-content.en.json")
        #expect(loadedDocument == expectedDocument)
    }

    @Test func weekUseCaseRejectsWeeksOutsideTheContentCoverage() async {
        let document = makeDocument(locale: "en", revision: 1)
        let repository = PregnancyContentRepository(
            expectedLocale: "en",
            bundleSource: PregnancyContentSourceStub(result: .document(document)),
            legacyCacheSource: EmptyPregnancyContentSource()
        )
        let useCase = LoadPregnancyWeekContentUseCase(repository: repository)

        let earlyContent = await useCase.execute(week: 5)
        let postTermContent = await useCase.execute(week: 44)

        #expect(earlyContent == nil)
        #expect(postTermContent == nil)
    }
}

private func decode(
    _ document: PregnancyContentDocument,
    expectedLocale: String
) throws -> PregnancyContentDocument {
    try PregnancyContentDocument.decodeValidated(
        from: JSONEncoder().encode(document),
        expectedLocale: expectedLocale
    )
}

private enum PregnancyContentSourceResult: Sendable {
    case document(PregnancyContentDocument?)
    case failure
}

private enum PregnancyContentSourceStubError: Error {
    case failed
}

private struct PregnancyContentSourceStub: PregnancyContentSourceProtocol {
    let result: PregnancyContentSourceResult

    func loadDocument() async throws -> PregnancyContentDocument? {
        switch result {
        case let .document(document):
            document
        case .failure:
            throw PregnancyContentSourceStubError.failed
        }
    }
}

private func makeDocument(locale: String, revision: Int) -> PregnancyContentDocument {
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
        schemaVersion: PregnancyContentDocument.supportedSchemaVersion,
        locale: locale,
        revision: revision,
        weeks: weeks
    )
}
