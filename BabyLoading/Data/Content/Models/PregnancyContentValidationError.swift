import Foundation

enum PregnancyContentValidationError: Error, Equatable {
    case unsupportedSchemaVersion(Int)
    case unsupportedLocale(String)
    case revisionNotNewer(current: Int, incoming: Int)
    case duplicateWeeks([Int])
    case invalidWeekCoverage([Int])
    case emptyKeyEvents(week: Int)
}
