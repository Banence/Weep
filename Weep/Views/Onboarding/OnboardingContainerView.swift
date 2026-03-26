import SwiftUI
import ClerkKit

struct OnboardingContainerView: View {
    @Environment(Clerk.self) private var clerk
    @State private var viewModel = OnboardingViewModel()
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            WeepColor.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.currentStep != .welcome && viewModel.currentStep != .greeting {
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

            // If user already has a Clerk session, skip sign-up and go to greeting or beyond
            if clerk.user != nil {
                if viewModel.currentStep == .welcome || viewModel.currentStep == .signUp {
                    viewModel.displayName = clerk.user?.firstName ?? clerk.user?.username ?? "there"
                    viewModel.currentStep = .greeting
                }
            }
        }
    }

    private var topBar: some View {
        ZStack {
            OnboardingProgressBar(progress: viewModel.progress)

            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if viewModel.firstScanSubView {
                            viewModel.firstScanSubView = false
                        } else {
                            viewModel.goBack()
                        }
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
        case .signUp:
            SignUpScreen(viewModel: viewModel) { advance() }
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
