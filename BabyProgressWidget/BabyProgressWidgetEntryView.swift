import Foundation
import SwiftUI

struct BabyProgressWidgetEntryView: View {
    var entry: BabyProgressTimelineProvider.Entry

    var body: some View {
        VStack {
            if let eventDate = entry.eventDate {
                let days = daysUntil(eventDate)

                Text("Semana \(entry.week)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("\(days)")
                    .font(.system(size: 40, weight: .bold))
                    .minimumScaleFactor(0.5)
                Text("días quedan")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                
                Text("El bebé es como \(entry.babySize.description)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("Configura la fecha en la app")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
    }

    func daysUntil(_ date: Date) -> Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        let startOfEventDate = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfEventDate)
        return max(0, components.day ?? 0)
    }
}
