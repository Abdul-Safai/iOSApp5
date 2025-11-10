import SwiftUI

enum Theme {
    // Soft purple/blue palette (feel free to tweak)
    static let background = LinearGradient(
        colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
        startPoint: .top, endPoint: .bottom
    )
    static let card = Color(.secondarySystemBackground)
    static let border = Color.black.opacity(0.05)
    static let brand = Color.accentColor // uses your app AccentColor
}
