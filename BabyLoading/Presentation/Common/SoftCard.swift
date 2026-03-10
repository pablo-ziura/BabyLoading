import SwiftUI

struct SoftCard: ViewModifier {
    var cornerRadius: CGFloat = 24

    func body(content: Content) -> some View {
        content
            .padding()
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
    }
}

extension View {
    func softCard(cornerRadius: CGFloat = 24) -> some View {
        modifier(SoftCard(cornerRadius: cornerRadius))
    }
}
