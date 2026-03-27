import SwiftUI

struct HouseholdScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 40)

                    Text("Who's in your\nhousehold?")
                        .font(WeepFont.largeTitle(32))
                        .foregroundColor(WeepColor.textPrimary)
                        .staggeredAppear(delay: 0.1)

                    Spacer().frame(height: 6)

                    Text("Helps us personalize portions and waste estimates")
                        .font(WeepFont.caption())
                        .foregroundColor(WeepColor.textSecondary)
                        .staggeredAppear(delay: 0.15)

                    Spacer().frame(height: 32)

                    VStack(spacing: 12) {
                        CounterRow(
                            icon: "person.2.fill",
                            label: "Adults",
                            count: $viewModel.householdAdults,
                            minimum: 1
                        )

                        CounterRow(
                            icon: "figure.and.child.holdinghands",
                            label: "Children",
                            count: $viewModel.householdChildren,
                            minimum: 0
                        )
                    }
                    .staggeredAppear(delay: 0.2)

                    Spacer().frame(height: 12)

                    // Pets
                    HStack(spacing: 14) {
                        Image(systemName: viewModel.hasPets ? "cat.fill" : "cat")
                            .font(.system(size: 18))
                            .foregroundColor(viewModel.hasPets ? WeepColor.accent : WeepColor.iconMuted)
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(viewModel.hasPets ? WeepColor.accentLight : WeepColor.background)
                            )
                            .animation(.snappy(duration: 0.15), value: viewModel.hasPets)

                        Text("Furry family members?")
                            .font(WeepFont.body())
                            .foregroundColor(WeepColor.textPrimary)

                        Spacer()

                        Toggle("", isOn: $viewModel.hasPets)
                            .labelsHidden()
                            .tint(WeepColor.accent)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(WeepColor.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(WeepColor.cardBorder, lineWidth: 1)
                    )
                    .staggeredAppear(delay: 0.3)

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 24)
            }

            BottomButtonBar {
                WeepButton(title: "Continue") { onContinue() }
            }
        }
    }
}

struct CounterRow: View {
    let icon: String
    let label: String
    @Binding var count: Int
    let minimum: Int

    var body: some View {
        HStack(spacing: 14) {
            // Icon in a tinted square
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(WeepColor.accent)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(WeepColor.accentLight)
                )

            Text(label)
                .font(WeepFont.bodyMedium())
                .foregroundColor(WeepColor.textPrimary)

            Spacer()

            // Stepper
            HStack(spacing: 0) {
                Button {
                    WeepHaptics.light()
                    if count > minimum { count -= 1 }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(count > minimum ? WeepColor.textPrimary : WeepColor.iconMuted.opacity(0.4))
                        .frame(width: 40, height: 40)
                }
                .disabled(count <= minimum)

                Text("\(count)")
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .foregroundColor(WeepColor.textPrimary)
                    .frame(width: 32)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.15), value: count)

                Button {
                    WeepHaptics.light()
                    count += 1
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(WeepColor.textPrimary)
                        .frame(width: 40, height: 40)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(WeepColor.background)
            )
        }
        .padding(.leading, 20)
        .padding(.trailing, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(WeepColor.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(WeepColor.cardBorder, lineWidth: 1)
        )
    }
}
