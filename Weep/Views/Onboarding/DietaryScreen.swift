import SwiftUI

struct DietaryScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 40)

                    Text("Any dietary\npreferences?")
                        .font(WeepFont.largeTitle(32))
                        .foregroundColor(WeepColor.textPrimary)
                        .staggeredAppear(delay: 0.1)

                    Spacer().frame(height: 6)

                    Text("We'll suggest recipes you'll actually want to cook")
                        .font(WeepFont.caption())
                        .foregroundColor(WeepColor.textSecondary)
                        .staggeredAppear(delay: 0.15)

                    Spacer().frame(height: 28)

                    FlowLayout(spacing: 10) {
                        ForEach(DietaryPreference.allCases, id: \.self) { pref in
                            DietaryTag(
                                label: pref.rawValue,
                                isSelected: viewModel.dietaryPreferences.contains(pref)
                            ) {
                                togglePreference(pref)
                            }
                        }
                    }
                    .staggeredAppear(delay: 0.2)

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 24)
            }

            BottomButtonBar {
                WeepButton(title: "Continue") { onContinue() }
            }
        }
    }

    private func togglePreference(_ pref: DietaryPreference) {
        if pref == .none {
            if viewModel.dietaryPreferences.contains(.none) {
                viewModel.dietaryPreferences.remove(.none)
            } else {
                viewModel.dietaryPreferences = [.none]
            }
        } else {
            viewModel.dietaryPreferences.remove(.none)
            if viewModel.dietaryPreferences.contains(pref) {
                viewModel.dietaryPreferences.remove(pref)
            } else {
                viewModel.dietaryPreferences.insert(pref)
            }
        }
    }
}

struct DietaryTag: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            WeepHaptics.selection()
            action()
        }) {
            HStack(spacing: 6) {
                Text(label)
                    .font(WeepFont.bodyMedium(15))
                    .foregroundColor(isSelected ? .white : WeepColor.textPrimary)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(isSelected ? WeepColor.accent : WeepColor.cardBackground)
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? WeepColor.accent : WeepColor.cardBorder,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .animation(.snappy(duration: 0.15), value: isSelected)
    }
}
