import SwiftUI

struct AboutYouScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("What should we\ncall you?")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(WeepColor.textPrimary)
                .multilineTextAlignment(.center)
                .staggeredAppear(delay: 0.1)

            Spacer().frame(height: 44)

            ZStack {
                if viewModel.displayName.isEmpty {
                    Text("Your name")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(WeepColor.placeholder)
                }
                TextField("", text: $viewModel.displayName)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(WeepColor.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .staggeredAppear(delay: 0.2)

            Spacer().frame(height: 14)

            Rectangle()
                .fill(WeepColor.divider)
                .frame(height: 1)
                .padding(.horizontal, 48)
                .staggeredAppear(delay: 0.2)

            Spacer()

            BottomButtonBar {
                WeepButton(
                    title: "Continue",
                    isEnabled: !viewModel.displayName.trimmingCharacters(in: .whitespaces).isEmpty
                ) {
                    onContinue()
                }
            }
        }
    }
}
