import SwiftUI

// Lightweight toast (not required elsewhere, safe placeholder)
struct Toast: ViewModifier {
    let message: String
    func body(content: Content) -> some View {
        ZStack {
            content
            VStack { Spacer()
                Text(message)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .shadow(radius: 2)
                    .padding(.bottom, 20)
            }
        }
    }
}
extension View {
    func toast(_ message: String) -> some View { modifier(Toast(message: message)) }
}
