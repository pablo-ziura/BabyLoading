@testable import BabyLoading
import XCTest

final class PregnancyContentDocumentTests: XCTestCase {
    func testDecodeValidated_acceptsValidDocument() throws {
        let data = try makeJSONData(document: makeDocument())

        let document = try PregnancyContentDocument.decodeValidated(from: data)

        XCTAssertEqual(document.weeks.count, PregnancyContentDocument.coveredWeeks.count)
        XCTAssertEqual(document.weeks.map(\.week), PregnancyContentDocument.coveredWeeks)
    }

    func testDecodeValidated_rejectsUnsupportedSchemaVersion() throws {
        var document = makeDocument()
        document = PregnancyContentDocument(
            schemaVersion: 2,
            locale: document.locale,
            revision: document.revision,
            weeks: document.weeks
        )

        XCTAssertThrowsError(try PregnancyContentDocument.decodeValidated(from: try makeJSONData(document: document))) { error in
            XCTAssertEqual(
                error as? PregnancyContentValidationError,
                .unsupportedSchemaVersion(2)
            )
        }
    }

    func testDecodeValidated_rejectsDuplicateWeeks() throws {
        var duplicateWeeks = makeDocument().weeks
        duplicateWeeks[1] = duplicateWeeks[0]
        let document = PregnancyContentDocument(
            schemaVersion: 1,
            locale: "es",
            revision: 1,
            weeks: duplicateWeeks
        )

        XCTAssertThrowsError(try PregnancyContentDocument.decodeValidated(from: try makeJSONData(document: document))) { error in
            XCTAssertEqual(
                error as? PregnancyContentValidationError,
                .duplicateWeeks([6])
            )
        }
    }

    func testDecodeValidated_rejectsIncompleteCoverage() throws {
        let document = PregnancyContentDocument(
            schemaVersion: 1,
            locale: "es",
            revision: 1,
            weeks: Array(makeDocument().weeks.prefix(2))
        )

        XCTAssertThrowsError(try PregnancyContentDocument.decodeValidated(from: try makeJSONData(document: document))) { error in
            XCTAssertEqual(
                error as? PregnancyContentValidationError,
                .invalidWeekCoverage([6, 7])
            )
        }
    }

    func testDecodeValidated_rejectsUnknownBabySize() {
        let json = """
        {
          "schemaVersion": 1,
          "locale": "es",
          "revision": 1,
          "weeks": [
            {
              "week": 6,
              "babySize": "dragonEgg",
              "babySizeLabel": "un dragon egg",
              "milestoneTitle": "Semana 6",
              "keyEvents": ["Evento"],
              "physiologicalImpact": "Impacto"
            }
          ]
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try PregnancyContentDocument.decodeValidated(from: json))
    }

    private func makeJSONData(document: PregnancyContentDocument) throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(document)
    }

    private func makeDocument(revision: Int = 1) -> PregnancyContentDocument {
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
            locale: "es",
            revision: revision,
            weeks: weeks
        )
    }
}
