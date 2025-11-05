import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    var onFinished: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 18) {
            // Hero
            ZStack {
                Circle()
                    .fill(AppTheme.gradient)
                    .frame(width: 160, height: 160)
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 56, weight: .bold))
            }
            .padding(.bottom, 8)
            .accessibilityHidden(true)

            // Title & subtitle
            Text("Welcome to UniMedia Notes")
                .font(.title2.weight(.bold))
            Text("Capture notes with images or videos, tag your location, and keep it all organized — locally with SwiftData.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            // Tips
            VStack(spacing: 10) {
                Label("Use + Add Note to start", systemImage: "plus.circle.fill")
                Label("Pick photos or videos", systemImage: "photo.on.rectangle.angled")
                Label("Share from the Details page", systemImage: "square.and.arrow.up")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .glassCard()

            // Primary action
            PrimaryButton(title: "Let’s go", systemImage: "checkmark.circle.fill") {
                onFinished?()
                isPresented = false
            }
            .padding(.top, 6)
        }
        .padding(24)
    }
}
