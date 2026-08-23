import Foundation
import SwiftUI
import WidgetKit

struct BabyProgressWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: BabyProgressTimelineProvider.Entry

    private var locale: Locale {
        Locale(identifier: entry.languageCode)
    }

    var body: some View {
        Group {
            if let eventDate = entry.eventDate {
                configuredView(eventDate: eventDate)
                    .unredacted()
            } else {
                emptyStateView
                    .unredacted()
            }
        }
        .environment(\.locale, locale)
    }

    @ViewBuilder
    private func configuredView(eventDate: Date) -> some View {
        let days = daysUntil(eventDate)
        let progress = min(Double(entry.week) / 40.0, 1.0)

        HStack(spacing: 0) {
            fruitProgressRing(progress: progress)

            VStack(alignment: .leading, spacing: 4) {
                Text(
                    String(
                        format: String(localized: "common.week", defaultValue: "Week %d", locale: locale),
                        locale: locale,
                        entry.week
                    )
                )
                    .font(BabyLoadingTypography.widget(size: 15, weight: .extraBold))
                    .foregroundStyle(.white)

                Text(
                    String(
                        format: String(
                            localized: "widget.babySize",
                            defaultValue: "The baby 🤰🏽 is now about the size of %@",
                            locale: locale
                        ),
                        locale: locale,
                        entry.babySizeLabel
                    )
                )
                    .font(BabyLoadingTypography.widget(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.6)

                Spacer(minLength: 4)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(days)")
                        .font(BabyLoadingTypography.widget(size: 28, weight: .extraBold))
                    Text("widget.days")
                        .font(BabyLoadingTypography.widget(size: 12, weight: .semibold))
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

            Image(entry.babySize.imageName)
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

            Text("widget.configureDate")
                .font(BabyLoadingTypography.widget(size: 13, weight: .medium))
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
                Color(red: 0.70, green: 0.55, blue: 0.82)
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
