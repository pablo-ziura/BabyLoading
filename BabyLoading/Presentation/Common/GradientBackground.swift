import BabyLoadingDesignTokens
import SwiftUI

struct GradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                BabyLoadingColors.backgroundGradientTop,
                BabyLoadingColors.backgroundGradientBottom
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

#Preview {
    GradientBackground()
}
