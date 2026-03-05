import SwiftUI

struct GradientBackground: View {
    private let gradientTop = Color(red: 1.0, green: 0.75, blue: 0.82)
    private let gradientBottom = Color(red: 0.78, green: 0.72, blue: 0.96)
    
    var body: some View {
        LinearGradient(
            colors: [gradientTop, gradientBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

#Preview {
    GradientBackground()
}
