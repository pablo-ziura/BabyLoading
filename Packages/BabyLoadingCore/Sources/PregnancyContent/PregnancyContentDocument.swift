import Foundation

public struct WeekContent: Codable, Equatable, Identifiable, Sendable {
    public let week: Int
    public let babySize: BabySize
    public let babySizeLabel: String
    public let milestoneTitle: String
    public let keyEvents: [String]
    public let physiologicalImpact: String?

    public var id: Int { week }

    public init(
        week: Int,
        babySize: BabySize,
        babySizeLabel: String,
        milestoneTitle: String,
        keyEvents: [String],
        physiologicalImpact: String?
    ) {
        self.week = week
        self.babySize = babySize
        self.babySizeLabel = babySizeLabel
        self.milestoneTitle = milestoneTitle
        self.keyEvents = keyEvents
        self.physiologicalImpact = physiologicalImpact
    }
}

public enum PregnancyContentValidationError: Error, Equatable, Sendable {
    case unsupportedSchemaVersion(Int)
    case unsupportedLocale(String)
    case revisionNotNewer(current: Int, incoming: Int)
    case duplicateWeeks([Int])
    case invalidWeekCoverage([Int])
    case emptyKeyEvents(week: Int)
}

public struct PregnancyContentDocument: Codable, Equatable, Sendable {
    public static let supportedSchemaVersion = 1
    public static let coveredWeeks = Array(6 ... 40)

    public let schemaVersion: Int
    public let locale: String
    public let revision: Int
    public let weeks: [WeekContent]

    public init(
        schemaVersion: Int,
        locale: String,
        revision: Int,
        weeks: [WeekContent]
    ) {
        self.schemaVersion = schemaVersion
        self.locale = locale
        self.revision = revision
        self.weeks = weeks
    }

    public static func empty(locale: String) -> PregnancyContentDocument {
        PregnancyContentDocument(
            schemaVersion: supportedSchemaVersion,
            locale: locale,
            revision: 0,
            weeks: []
        )
    }

    public func validated(
        expectedLocale: String,
        minimumRevision: Int? = nil
    ) throws -> PregnancyContentDocument {
        guard schemaVersion == Self.supportedSchemaVersion else {
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
            .compactMap { week, values in values.count > 1 ? week : nil }
            .sorted()
        guard duplicateWeeks.isEmpty else {
            throw PregnancyContentValidationError.duplicateWeeks(duplicateWeeks)
        }

        let normalizedWeeks = weeks.sorted { $0.week < $1.week }
        let receivedWeeks = normalizedWeeks.map(\.week)
        guard receivedWeeks == Self.coveredWeeks else {
            throw PregnancyContentValidationError.invalidWeekCoverage(receivedWeeks)
        }

        if let invalidWeek = normalizedWeeks.first(where: { weekContent in
            weekContent.keyEvents.isEmpty
                || weekContent.keyEvents.contains {
                    $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }
        })?.week {
            throw PregnancyContentValidationError.emptyKeyEvents(week: invalidWeek)
        }

        return PregnancyContentDocument(
            schemaVersion: schemaVersion,
            locale: locale,
            revision: revision,
            weeks: normalizedWeeks
        )
    }

    public static func decodeValidated(
        from data: Data,
        expectedLocale: String,
        minimumRevision: Int? = nil
    ) throws -> PregnancyContentDocument {
        let document = try JSONDecoder().decode(PregnancyContentDocument.self, from: data)
        return try document.validated(
            expectedLocale: expectedLocale,
            minimumRevision: minimumRevision
        )
    }
}
