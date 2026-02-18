import SwiftUI

struct JourneyView: View {
    var viewModel: BabyProgressViewModel

    var body: some View {
        ZStack {
            GradientBackground()

            ScrollView {
                VStack(spacing: 0) {
                    Text("Tu embarazo semana a semana")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.top, 24)
                        .padding(.bottom, 16)

                    LazyVStack(spacing: 0) {
                        ForEach(6 ... 40, id: \.self) { week in
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
}

#Preview {
    ZStack {
        GradientBackground()
        JourneyView(viewModel: BabyProgressViewModel())
    }
}
