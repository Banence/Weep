import SwiftUI

struct RootView: View {
    @State private var showOnboarding: Bool

    init() {
        _showOnboarding = State(initialValue: !OnboardingViewModel.hasCompletedOnboarding)
    }

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingContainerView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showOnboarding = false
                    }
                }
                .transition(.opacity)
            } else {
                HomeView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showOnboarding)
    }
}

struct HomeView: View {
    var body: some View {
        ZStack {
            WeepColor.background.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "refrigerator")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(WeepColor.iconMuted)

                Text("My Kitchen")
                    .font(WeepFont.largeTitle(24))
                    .foregroundColor(WeepColor.textPrimary)

                Text("Your food inventory will appear here")
                    .font(WeepFont.caption())
                    .foregroundColor(WeepColor.textSecondary)
            }
        }
    }
}
