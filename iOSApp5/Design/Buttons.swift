import SwiftUI

struct PrimaryButton: View {
    var title: String
    var systemImage: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let s = systemImage { Image(systemName: s) }
                Text(title).fontWeight(.semibold)
            }
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(AppTheme.gradient)
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.corner, style: .continuous))
            .shadow(radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
