import Foundation
import SwiftUI

struct WeekRow: View {
    let content: WeekContent
    let isCurrent: Bool
    let currentWeek: Int?
    let currentDayOffset: Int

    private var highlightedTopDay: Int? {
        guard let currentWeek, currentWeek + 1 == content.week, (4 ... 6).contains(currentDayOffset) else {
            return nil
        }
        return currentDayOffset - 4
    }

    private var highlightedBottomDay: Int? {
        guard currentWeek == content.week, (0 ... 3).contains(currentDayOffset) else {
            return nil
        }
        return currentDayOffset
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 0) {
                TimelineDaySegment(
                    dayCount: 3,
                    highlightedDayIndex: highlightedTopDay
                )

                Circle()
                    .fill(isCurrent ? .pink : .white.opacity(0.5))
                    .frame(width: isCurrent ? 14 : 8, height: isCurrent ? 14 : 8)
                    .overlay {
                        if isCurrent {
                            Circle()
                                .strokeBorder(.white, lineWidth: 2)
                        }
                    }

                TimelineDaySegment(
                    dayCount: 4,
                    highlightedDayIndex: highlightedBottomDay
                )
            }
            .frame(width: 16)

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 40, height: 40)

                    Image(content.babySize.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 34, height: 34)
                        .clipShape(Circle())

                    Circle()
                        .strokeBorder(.pink.opacity(0.2), lineWidth: 1.5)
                        .frame(width: 40, height: 40)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Semana \(content.week)")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(isCurrent ? .bold : .medium)

                    Text(content.babySizeLabel.capitalized)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isCurrent {
                    Text("Aquí estás")
                        .font(.system(.caption2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [.pink, .purple.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isCurrent ? .white : .white.opacity(0.6))
            )
            .shadow(color: isCurrent ? .pink.opacity(0.15) : .clear, radius: 8, y: 4)
            .padding(.vertical, 6)
        }
    }
}

private struct TimelineDaySegment: View {
    let dayCount: Int
    let highlightedDayIndex: Int?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Rectangle()
                    .fill(.white.opacity(0.3))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)

                ForEach(0 ..< dayCount, id: \.self) { index in
                    let isHighlighted = index == highlightedDayIndex
                    let yPosition = proxy.size.height * (CGFloat(index + 1) / 4)

                    Circle()
                        .fill(isHighlighted ? .pink : .white.opacity(0.65))
                        .frame(width: isHighlighted ? 7 : 4, height: isHighlighted ? 7 : 4)
                        .overlay {
                            if isHighlighted {
                                Circle()
                                    .strokeBorder(.white, lineWidth: 1)
                            }
                        }
                        .position(x: proxy.size.width / 2, y: yPosition)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
}
