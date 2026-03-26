import SwiftUI

struct FirstScanScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    @State private var showCamera = false
    @State private var manualItemName = ""
    @State private var showCelebration = false

    private var showManualEntry: Bool {
        get { viewModel.firstScanSubView }
        nonmutating set { viewModel.firstScanSubView = newValue }
    }

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
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView(
                onComplete: { item in
                    KitchenStore.shared.addItem(item)
                    showCamera = false
                    viewModel.firstItemAdded = true
                    withAnimation(.easeInOut(duration: 0.3)) { showCelebration = true }
                },
                onDismiss: {
                    showCamera = false
                }
            )
        }
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
                        scanOption(
                            icon: "camera.fill",
                            title: "Snap a photo",
                            subtitle: "Photo of any product"
                        ) {
                            WeepHaptics.light()
                            showCamera = true
                        }

                        scanOption(
                            icon: "pencil.line",
                            title: "Add manually",
                            subtitle: "Type in the product name"
                        ) {
                            WeepHaptics.light()
                            withAnimation(.easeInOut(duration: 0.3)) { showManualEntry = true }
                        }
                    }
                    .staggeredAppear(delay: 0.2)

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func scanOption(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(WeepColor.accent)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(WeepColor.accentLight)
                    )

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
            Spacer()

            VStack(spacing: 24) {
                Text("What are you adding?")
                    .font(WeepFont.headline(22))
                    .foregroundColor(WeepColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                VStack(spacing: 12) {
                    TextField("", text: $manualItemName, prompt:
                        Text("e.g. Milk, Bananas, Yogurt")
                            .foregroundStyle(WeepColor.placeholder)
                    )
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(WeepColor.textPrimary)
                    .tint(WeepColor.accent)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                    Rectangle()
                        .fill(WeepColor.cardBorder)
                        .frame(height: 1)
                        .padding(.horizontal, 40)
                }
            }

            Spacer()

            VStack(spacing: 0) {
                WeepButton(
                    title: "Add to my kitchen",
                    isEnabled: !manualItemName.trimmingCharacters(in: .whitespaces).isEmpty
                ) {
                    WeepHaptics.success()
                    let item = FoodItem(name: manualItemName.trimmingCharacters(in: .whitespaces))
                    KitchenStore.shared.addItem(item)
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
