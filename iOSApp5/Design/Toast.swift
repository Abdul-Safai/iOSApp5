import SwiftUI

struct Toast: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .shadow(radius: 8)
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityAddTraits(.isStaticText)
    }
}

struct ToastHost<Content: View>: View {
    @Binding var message: String?
    let content: Content
    init(message: Binding<String?>, @ViewBuilder content: () -> Content) {
        _message = message; self.content = content()
    }

    var body: some View {
        ZStack(alignment: .top) {
            content
            if let msg = message {
                Toast(text: msg)
                    .padding(.top, 8)
                    .zIndex(1)
            }
        }
        .animation(.spring(duration: 0.35), value: message)
    }
}
