import SwiftUI

enum TabItem: Int, CaseIterable {
    case dashboard
    case journey
    case gallery
    case settings

    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .journey:   return "calendar"
        case .gallery:   return "photo.on.rectangle"
        case .settings:  return "gearshape"
        }
    }

    var title: String {
        switch self {
        case .dashboard: return "Inicio"
        case .journey:   return "Semanas"
        case .gallery:   return "Galería"
        case .settings:  return "Ajustes"
        }
    }
}

struct PillTabBar: View {
    @Binding var selectedTab: TabItem

    private let gradientColors: [Color] = [.pink, .purple.opacity(0.8)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: selectedTab == tab ? .bold : .regular))
                            .symbolRenderingMode(.hierarchical)

                        Text(tab.title)
                            .font(.system(size: 10, design: .rounded))
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                    }
                    .foregroundStyle(
                        selectedTab == tab
                            ? AnyShapeStyle(LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(.secondary)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .pink.opacity(0.2), radius: 16, y: 4)
        )
        .padding(.horizontal, 24)
    }
}

#Preview {
    ZStack {
        Color.pink.opacity(0.1).ignoresSafeArea()
        VStack {
            Spacer()
            PillTabBar(selectedTab: .constant(.dashboard))
        }
    }
}
