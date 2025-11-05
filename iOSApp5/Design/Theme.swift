import SwiftUI

enum AppTheme {
    static let corner: CGFloat = 16
    static let cardShadow = 0.08

    static let gradient = LinearGradient(
        colors: [Color.accentColor.opacity(0.35), Color.blue.opacity(0.25)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func cardBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04)
    }
}

struct GlassCard: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content
            .background(AppTheme.cardBackground(scheme))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.corner, style: .continuous))
            .shadow(color: .black.opacity(AppTheme.cardShadow), radius: 10, x: 0, y: 6)
    }
}

extension View {
    func glassCard() -> some View { modifier(GlassCard()) }
}
