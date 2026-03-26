import SwiftUI

struct FirstScanScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    @State private var showManualEntry = false
    @State private var manualItemName = ""
    @State private var showCelebration = false

    var body: some View {
        Group {
            if showCelebration {
                celebrationView
            } else if showManualEntry {
                manualEntryView
            } else {
                mainView
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showManualEntry)
        .animation(.easeInOut(duration: 0.3), value: showCelebration)
    }

    // MARK: - Main

    private var mainView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 40)

                    Text("Add your\nfirst item")
                        .font(WeepFont.largeTitle(32))
                        .foregroundColor(WeepColor.textPrimary)
                        .staggeredAppear(delay: 0.1)

                    Spacer().frame(height: 6)

                    Text("Experience the magic of tracking")
                        .font(WeepFont.caption())
                        .foregroundColor(WeepColor.textSecondary)
                        .staggeredAppear(delay: 0.15)

                    Spacer().frame(height: 32)

                    VStack(spacing: 10) {
                        scanOption(title: "Scan a barcode", subtitle: "Point at any product barcode")
                        scanOption(title: "Snap a photo", subtitle: "Photo of any fruit or vegetable")
                        scanOption(title: "Add manually", subtitle: "Type in the product name")
                    }
                    .staggeredAppear(delay: 0.2)

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func scanOption(title: String, subtitle: String) -> some View {
        Button {
            WeepHaptics.light()
            withAnimation(.easeInOut(duration: 0.3)) { showManualEntry = true }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(WeepFont.bodyMedium(16))
                        .foregroundColor(WeepColor.textPrimary)
                    Text(subtitle)
                        .font(WeepFont.caption(14))
                        .foregroundColor(WeepColor.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(WeepColor.iconMuted)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(WeepColor.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(WeepColor.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Manual Entry

    private var manualEntryView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 80)

                    Text("What are you adding?")
                        .font(WeepFont.headline(22))
                        .foregroundColor(WeepColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .staggeredAppear(delay: 0.05)

                    Spacer().frame(height: 28)

                    ZStack {
                        if manualItemName.isEmpty {
                            Text("e.g. Milk, Bananas, Yogurt")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(WeepColor.placeholder)
                        }
                        TextField("", text: $manualItemName)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(WeepColor.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                    .staggeredAppear(delay: 0.1)

                    Spacer().frame(height: 12)

                    Rectangle()
                        .fill(WeepColor.divider)
                        .frame(height: 1)
                        .padding(.horizontal, 40)
                        .staggeredAppear(delay: 0.1)

                    Spacer(minLength: 100)
                }
            }
            .scrollDismissesKeyboard(.interactively)

            VStack(spacing: 0) {
                WeepButton(
                    title: "Add to my kitchen",
                    isEnabled: !manualItemName.trimmingCharacters(in: .whitespaces).isEmpty
                ) {
                    WeepHaptics.success()
                    viewModel.firstItemAdded = true
                    withAnimation(.easeInOut(duration: 0.3)) { showCelebration = true }
                }

                Button("Go back") {
                    withAnimation(.easeInOut(duration: 0.3)) { showManualEntry = false }
                }
                .font(WeepFont.body(15))
                .foregroundColor(WeepColor.textSecondary)
                .frame(height: 48)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Celebration

    private var celebrationView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 120)

                    ZStack {
                        Circle()
                            .fill(WeepColor.accentLight)
                            .frame(width: 80, height: 80)

                        Image(systemName: "checkmark")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundColor(WeepColor.accent)
                    }
                    .frame(maxWidth: .infinity)
                    .staggeredAppear(delay: 0.1)

                    Spacer().frame(height: 24)

                    Text("You're all set.\nYour first item is tracked!")
                        .font(WeepFont.largeTitle(28))
                        .foregroundColor(WeepColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .staggeredAppear(delay: 0.2)

                    Spacer(minLength: 100)
                }
            }

            BottomButtonBar {
                WeepButton(title: "Get started") {
                    viewModel.complete()
                    onComplete()
                }
            }
            .staggeredAppear(delay: 0.4)
        }
    }
}
