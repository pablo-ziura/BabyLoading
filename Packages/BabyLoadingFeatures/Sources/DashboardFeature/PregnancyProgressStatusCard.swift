import BabyLoadingDesignComponents
import BabyLoadingDesignTokens
import PregnancyProgress
import SwiftUI

struct PregnancyProgressStatusCard: View {
    let progress: ActivePregnancyProgress

    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: BabyLoadingSpacing.small) {
            Text(phaseTitle)
                .font(BabyLoadingTypography.text(.headline, weight: .bold))
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h2)

            Text(phaseMessage)
                .font(BabyLoadingTypography.text(.body))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .softCard()
        .accessibilityElement(children: .combine)
    }

    private var phaseTitle: LocalizedStringKey {
        switch progress.phase {
        case .ongoing:
            ""
        case .lateTerm:
            "pregnancy.status.lateTerm.title"
        case .postTerm:
            "pregnancy.status.postTerm.title"
        }
    }

    private var phaseMessage: LocalizedStringKey {
        switch progress.phase {
        case .ongoing:
            ""
        case .lateTerm:
            "pregnancy.status.lateTerm.message"
        case .postTerm:
            "pregnancy.status.postTerm.message"
        }
    }

    private var dueDateRelationText: String {
        switch progress.dueDateRelation {
        case let .upcoming(days):
            String(
                format: String(
                    localized: "pregnancy.status.dueDateUpcoming",
                    defaultValue: "%d days until your estimated due date",
                    locale: locale
                ),
                locale: locale,
                days
            )
        case .today:
            String(
                localized: "pregnancy.status.dueDateToday",
                defaultValue: "Estimated due date today",
                locale: locale
            )
        case let .elapsed(days):
            String(
                format: String(
                    localized: "pregnancy.status.dueDateElapsed",
                    defaultValue: "%d days since your estimated due date",
                    locale: locale
                ),
                locale: locale,
                days
            )
        }
    }
}
