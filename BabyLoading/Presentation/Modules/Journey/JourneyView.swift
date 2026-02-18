import SwiftUI

struct JourneyView: View {
    var viewModel: BabyProgressViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // MARK: - Header
                Text("Tu embarazo semana a semana")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.top, 24)
                    .padding(.bottom, 16)

                // MARK: - Timeline
                LazyVStack(spacing: 0) {
                    ForEach(6...40, id: \.self) { week in
                        let size = BabySize.from(week: week)
                        let isCurrent = viewModel.pregnancyWeek == week

                        WeekRow(
                            week: week,
                            babySize: size,
                            isCurrent: isCurrent
                        )
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 100)
            }
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Week Row

private struct WeekRow: View {
    let week: Int
    let babySize: BabySize
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Timeline dot + line
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
            .frame(width: 16) // Fixed width for timeline column

            // Content
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

#Preview {
    ZStack {
        GradientBackground()
        JourneyView(viewModel: BabyProgressViewModel())
    }
}
