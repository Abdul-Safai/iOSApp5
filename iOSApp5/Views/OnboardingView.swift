import SwiftUI

struct OnboardingView: View {
    var done: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "sparkles").font(.system(size: 64))
            Text("Welcome to iOSApp5 Notes").font(.title2).bold()
            Text("New features: SwiftData, PhotosPicker, Map tags, ShareLink, local notifications, and haptics.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            Button("Get started") { done() }
                .buttonStyle(PrimaryProminentButtonStyle())
        }
        .padding()
        .presentationDetents([.height(300)])
    }
}
