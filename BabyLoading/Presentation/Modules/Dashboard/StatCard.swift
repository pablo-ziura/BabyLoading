import Foundation
import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.pink, .purple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(value)
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .softCard()
    }
}
