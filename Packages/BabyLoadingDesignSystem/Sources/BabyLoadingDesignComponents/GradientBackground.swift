import BabyLoadingDesignTokens
import SwiftUI

public struct GradientBackground: View {
    public init() {}

    public var body: some View {
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
