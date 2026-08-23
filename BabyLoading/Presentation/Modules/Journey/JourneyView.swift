import BabyLoadingDesignTokens
import PregnancyContent
import SwiftUI

struct JourneyView: View {
    @Environment(BabyProgressViewModel.self) private var viewModel

    private var currentDayOffset: Int {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: viewModel.lastPeriodDate)
        let today = calendar.startOfDay(for: .now)
        let elapsedDays = calendar.dateComponents([.day], from: startDate, to: today).day ?? 0
        return max(0, elapsedDays) % 7
    }

    var body: some View {
        ZStack {
            GradientBackground()

            ScrollView {
                VStack(spacing: 0) {
                    Text("journey.title")
                        .font(BabyLoadingTypography.text(.title2, weight: .bold))
                        .foregroundStyle(.primary)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h1)
                        .padding(.top, 24)
                        .padding(.bottom, 16)

                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.allWeekContent) { content in
                            let isCurrent = viewModel.pregnancyWeek == content.week

                            WeekRow(
                                content: content,
                                isCurrent: isCurrent,
                                currentWeek: viewModel.pregnancyWeek,
                                currentDayOffset: currentDayOffset
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
    let coordinator = Coordinator()
    ZStack {
        GradientBackground()
        JourneyView()
            .environment(coordinator.viewModel)
    }
}
