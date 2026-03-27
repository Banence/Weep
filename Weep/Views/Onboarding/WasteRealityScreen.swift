import SwiftUI

struct WasteRealityScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    private var sliderLabel: String {
        switch viewModel.selfReportedWasteLevel {
        case 0..<0.3: return "Almost nothing"
        case 0.3..<0.6: return "A bag or two"
        case 0.6..<0.85: return "More than I'd like"
        default: return "Way too much"
        }
    }

    private var sliderIcon: String {
        switch viewModel.selfReportedWasteLevel {
        case 0..<0.3: return "leaf.fill"
        case 0.3..<0.6: return "bag.fill"
        case 0.6..<0.85: return "trash.fill"
        default: return "exclamationmark.triangle.fill"
        }
    }

    private var sliderIconColor: Color {
        switch viewModel.selfReportedWasteLevel {
        case 0..<0.3: return WeepColor.accent
        case 0.3..<0.6: return WeepColor.alertAmber
        case 0.6..<0.85: return WeepColor.secondary
        default: return WeepColor.alertRed
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 40)

                    Text("How much food do\nyou waste each week?")
                        .font(WeepFont.largeTitle(32))
                        .foregroundColor(WeepColor.textPrimary)
                        .staggeredAppear(delay: 0.1)

                    Spacer().frame(height: 48)

                    // Big emoji + label centered
                    VStack(spacing: 12) {
                        Image(systemName: sliderIcon)
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(sliderIconColor)
                            .contentTransition(.symbolEffect(.replace))
                            .animation(.snappy(duration: 0.25), value: sliderIcon)

                        Text(sliderLabel)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(WeepColor.textPrimary)
                            .contentTransition(.numericText())
                    }
                    .frame(maxWidth: .infinity)
                    .animation(.snappy(duration: 0.2), value: sliderLabel)
                    .staggeredAppear(delay: 0.2)

                    Spacer().frame(height: 32)

                    // Slider
                    Slider(value: $viewModel.selfReportedWasteLevel, in: 0...1) { editing in
                        if !editing { WeepHaptics.selection() }
                    }
                    .tint(WeepColor.accent)
                    .staggeredAppear(delay: 0.25)

                    Spacer().frame(height: 6)

                    HStack {
                        Text("Almost nothing")
                        Spacer()
                        Text("A lot")
                    }
                    .font(WeepFont.caption(12))
                    .foregroundColor(WeepColor.iconMuted)
                    .staggeredAppear(delay: 0.25)

                    Spacer().frame(height: 40)

                    // Cost estimate — big number, no card
                    VStack(spacing: 4) {
                        Text("€\(Int(viewModel.estimatedMonthlyWasteCost))")
                            .font(.system(size: 56, weight: .bold, design: .default))
                            .foregroundColor(WeepColor.textPrimary)
                            .contentTransition(.numericText())
                            .animation(.snappy(duration: 0.15), value: Int(viewModel.estimatedMonthlyWasteCost))

                        Text("estimated monthly waste")
                            .font(WeepFont.caption(14))
                            .foregroundColor(WeepColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .staggeredAppear(delay: 0.3)

                    Spacer().frame(height: 32)

                    // Empathy note
                    Text("No judgment — most people underestimate this.\nThat's exactly why we built Weep.")
                        .font(WeepFont.caption(14))
                        .foregroundColor(WeepColor.iconMuted)
                        .lineSpacing(3)
                        .staggeredAppear(delay: 0.35)

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
