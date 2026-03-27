import SwiftUI

struct WelcomeScreen: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo
            Image("WeepLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                .staggeredAppear(delay: 0.0)

            Spacer().frame(height: 24)

            // Headline
            Text("Welcome to Weep")
                .font(WeepFont.largeTitle(28))
                .foregroundColor(WeepColor.textPrimary)
                .multilineTextAlignment(.center)
                .staggeredAppear(delay: 0.1)

            Spacer().frame(height: 12)

            Text("Before you begin, let's take a few\nminutes to learn more about you!")
                .font(WeepFont.body(17))
                .foregroundColor(WeepColor.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .staggeredAppear(delay: 0.25)

            Spacer()

            // CTA
            BottomButtonBar {
                WeepButton(title: "Continue") {
                    onContinue()
                }
            }
            .staggeredAppear(delay: 0.45)
        }
    }
}
