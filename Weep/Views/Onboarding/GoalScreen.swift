import SwiftUI

struct GoalScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 40)

                    Text("What's your\nWeep goal?")
                        .font(WeepFont.largeTitle(32))
                        .foregroundColor(WeepColor.textPrimary)
                        .staggeredAppear(delay: 0.1)

                    Spacer().frame(height: 6)

                    Text("We'll tailor your experience and track progress")
                        .font(WeepFont.caption())
                        .foregroundColor(WeepColor.textSecondary)
                        .staggeredAppear(delay: 0.15)

                    Spacer().frame(height: 32)

                    VStack(spacing: 10) {
                        ForEach(PrimaryGoal.allCases, id: \.self) { goal in
                            SelectionCard(
                                title: goal.rawValue,
                                subtitle: goal.subtitle,
                                isSelected: viewModel.primaryGoal == goal
                            ) {
                                viewModel.primaryGoal = goal
                            }
                        }
                    }
                    .staggeredAppear(delay: 0.2)

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 24)
            }

            BottomButtonBar {
                WeepButton(
                    title: "Continue",
                    isEnabled: viewModel.primaryGoal != nil
                ) { onContinue() }
            }
        }
    }
}
