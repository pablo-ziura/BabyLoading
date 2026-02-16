import Foundation
import SwiftUI
import WidgetKit

struct BabyProgressWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: BabyProgressTimelineProvider.Entry

    var body: some View {
        if let eventDate = entry.eventDate {
            configuredView(eventDate: eventDate)
                .unredacted()
        } else {
            emptyStateView
                .unredacted()
        }
    }

    @ViewBuilder
    private func configuredView(eventDate: Date) -> some View {
        let days = daysUntil(eventDate)
        let progress = min(Double(entry.week) / 40.0, 1.0)

        HStack(spacing: 0) {
            fruitProgressRing(progress: progress)

            VStack(alignment: .leading, spacing: 4) {
                Text("Semana \(entry.week)")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("El bebé 🤰🏽 ahora tiene el tamaño de \(entry.babySize.description)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.6)

                Spacer(minLength: 4)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(days)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                    Text("días")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.2))
                            .frame(height: 4)
                        Capsule()
                            .fill(.white)
                            .frame(width: geo.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
            }
            .padding(.leading, 10)
        }
        .containerBackground(for: .widget) {
            widgetGradient
        }
    }

    private func fruitProgressRing(progress: Double) -> some View {
        let ringSize: CGFloat = family == .systemMedium ? 100 : 74
        let lineWidth: CGFloat = 5
        let imageSize: CGFloat = ringSize - lineWidth * 2

        return ZStack {
            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: ringSize, height: ringSize)

            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: lineWidth)
                .frame(width: ringSize, height: ringSize)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.white,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: ringSize, height: ringSize)

            Image("img_\(entry.babySize.rawValue.lowercased())")
                .resizable()
                .scaledToFill()
                .frame(width: imageSize, height: imageSize)
                .clipShape(Circle())
        }
    }

    private var emptyStateView: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.8))

            Text("Configura la fecha\nen la app")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .multilineTextAlignment(.leading)
                .foregroundStyle(.white.opacity(0.7))
        }
        .containerBackground(for: .widget) {
            widgetGradient
        }
    }

    private var widgetGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.93, green: 0.55, blue: 0.67),
                Color(red: 0.70, green: 0.55, blue: 0.82),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func daysUntil(_ date: Date) -> Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        let startOfEventDate = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfEventDate)
        return max(0, components.day ?? 0)
    }
}
