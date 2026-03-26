import SwiftUI

struct OnboardingContainerView: View {
    @State private var viewModel = OnboardingViewModel()
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            WeepColor.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.currentStep != .welcome {
                    topBar
                        .transition(.opacity)
                }

                screenContent
                    .frame(maxHeight: .infinity)
                    .id(viewModel.currentStep)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
        .onAppear {
            viewModel.restoreFromUserDefaults()
        }
    }

    private var topBar: some View {
        ZStack {
            // Centered progress bar
            OnboardingProgressBar(progress: viewModel.progress)

            // Back button left, skip right
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.goBack()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(WeepColor.textPrimary)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                if viewModel.currentStep.canSkip {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.skip()
                        }
                    } label: {
                        Text("Skip")
                            .font(WeepFont.caption(15))
                            .foregroundColor(WeepColor.textSecondary)
                            .frame(height: 44)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var screenContent: some View {
        switch viewModel.currentStep {
        case .welcome:
            WelcomeScreen { advance() }
        case .aboutYou:
            AboutYouScreen(viewModel: viewModel) { advance() }
        case .greeting:
            GreetingScreen(name: viewModel.displayName) { advance() }
        case .household:
            HouseholdScreen(viewModel: viewModel) { advance() }
        case .shoppingFrequency:
            ShoppingFrequencyScreen(viewModel: viewModel) { advance() }
        case .shoppingLocations:
            ShoppingLocationsScreen(viewModel: viewModel) { advance() }
        case .kitchenZones:
            KitchenZonesScreen(viewModel: viewModel) { advance() }
        case .dietary:
            DietaryScreen(viewModel: viewModel) { advance() }
        case .wasteReality:
            WasteRealityScreen(viewModel: viewModel) { advance() }
        case .goal:
            GoalScreen(viewModel: viewModel) { advance() }
        case .permissions:
            PermissionsScreen(viewModel: viewModel) { advance() }
        case .firstScan:
            FirstScanScreen(viewModel: viewModel) { onComplete() }
        }
    }

    private func advance() {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.advance()
        }
    }
}

#Preview {
    OnboardingContainerView(onComplete: {})
}
