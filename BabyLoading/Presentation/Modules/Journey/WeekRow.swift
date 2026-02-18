import Foundation
import SwiftUI

struct WeekRow: View {
    let week: Int
    let babySize: BabySize
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(.white.opacity(0.3))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)

                Circle()
                    .fill(isCurrent ? .pink : .white.opacity(0.5))
                    .frame(width: isCurrent ? 14 : 8, height: isCurrent ? 14 : 8)
                    .overlay {
                        if isCurrent {
                            Circle()
                                .strokeBorder(.white, lineWidth: 2)
                        }
                    }

                Rectangle()
                    .fill(.white.opacity(0.3))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 16)

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 40, height: 40)

                    Image(babySize.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 34, height: 34)
                        .clipShape(Circle())

                    Circle()
                        .strokeBorder(.pink.opacity(0.2), lineWidth: 1.5)
                        .frame(width: 40, height: 40)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Semana \(week)")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(isCurrent ? .bold : .medium)

                    Text(babySize.description.capitalized)
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
