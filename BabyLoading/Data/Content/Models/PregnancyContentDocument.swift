import Foundation

struct PregnancyContentDocument: Codable, Equatable {
    static let schemaVersionSupported = 1
    static let coveredWeeks = Array(6 ... 40)
    static let empty = empty(locale: PregnancyContentLocalization.fallbackLocale)

    let schemaVersion: Int
    let locale: String
    let revision: Int
    let weeks: [WeekContent]

    static func empty(locale: String) -> PregnancyContentDocument {
        PregnancyContentDocument(
            schemaVersion: schemaVersionSupported,
            locale: locale,
            revision: 0,
            weeks: []
        )
    }

    func validated(expectedLocale: String, minimumRevision: Int? = nil) throws -> PregnancyContentDocument {
        guard schemaVersion == Self.schemaVersionSupported else {
            throw PregnancyContentValidationError.unsupportedSchemaVersion(schemaVersion)
        }

        guard locale == expectedLocale else {
            throw PregnancyContentValidationError.unsupportedLocale(locale)
        }

        if let minimumRevision, revision <= minimumRevision {
            throw PregnancyContentValidationError.revisionNotNewer(
                current: minimumRevision,
                incoming: revision
            )
        }

        let groupedByWeek = Dictionary(grouping: weeks, by: \.week)
        let duplicateWeeks = groupedByWeek
            .compactMap { key, value in value.count > 1 ? key : nil }
            .sorted()

        guard duplicateWeeks.isEmpty else {
            throw PregnancyContentValidationError.duplicateWeeks(duplicateWeeks)
        }

        let normalizedWeeks = weeks.sorted { $0.week < $1.week }
        let coveredWeeks = normalizedWeeks.map(\.week)

        guard coveredWeeks == Self.coveredWeeks else {
            throw PregnancyContentValidationError.invalidWeekCoverage(coveredWeeks)
        }

        if let emptyEventsWeek = normalizedWeeks.first(where: { weekContent in
            weekContent.keyEvents.isEmpty
                || weekContent.keyEvents.contains(where: {
                    $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                })
        })?.week {
            throw PregnancyContentValidationError.emptyKeyEvents(week: emptyEventsWeek)
        }

        return PregnancyContentDocument(
            schemaVersion: schemaVersion,
            locale: locale,
            revision: revision,
            weeks: normalizedWeeks
        )
    }

    static func decodeValidated(
        from data: Data,
        expectedLocale: String,
        minimumRevision: Int? = nil
    ) throws -> PregnancyContentDocument {
        let decoder = JSONDecoder()
        let document = try decoder.decode(PregnancyContentDocument.self, from: data)
        return try document.validated(expectedLocale: expectedLocale, minimumRevision: minimumRevision)
    }
}
