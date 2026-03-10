import Foundation

struct WeekContent: Codable, Equatable, Identifiable {
    let week: Int
    let babySize: BabySize
    let babySizeLabel: String
    let milestoneTitle: String
    let keyEvents: [String]
    let physiologicalImpact: String?

    var id: Int { week }
}
