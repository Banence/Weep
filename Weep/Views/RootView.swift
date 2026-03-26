import SwiftUI
import ClerkKit

struct RootView: View {
    @Environment(Clerk.self) private var clerk
    @State private var onboardingDone = OnboardingViewModel.hasCompletedOnboarding

    var body: some View {
        Group {
            if !onboardingDone {
                // Show onboarding immediately — no waiting for Clerk
                OnboardingContainerView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        onboardingDone = true
                    }
                }
                .transition(.opacity)
            } else if !clerk.isLoaded {
                // Only wait for Clerk after onboarding (need auth state for home vs sign-in)
                ZStack {
                    WeepColor.background.ignoresSafeArea()
                }
            } else if clerk.user == nil {
                SignedOutView()
                    .transition(.opacity)
            } else {
                HomeView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: onboardingDone)
        .animation(.easeInOut(duration: 0.3), value: clerk.isLoaded)
        .animation(.easeInOut(duration: 0.3), value: clerk.user?.id)
    }
}

// MARK: - Signed Out (returning user)

struct SignedOutView: View {
    @Environment(Clerk.self) private var clerk
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            WeepColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 12) {
                    Text("Welcome back")
                        .font(WeepFont.largeTitle(32))
                        .foregroundColor(WeepColor.textPrimary)

                    Text("Sign in to continue")
                        .font(WeepFont.body(16))
                        .foregroundColor(WeepColor.textSecondary)
                }

                Spacer()

                VStack(spacing: 16) {
                    if let errorMessage {
                        Text(errorMessage)
                            .font(WeepFont.caption(13))
                            .foregroundColor(WeepColor.secondary)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }

                    Button {
                        signIn { try await clerk.auth.signInWithApple() }
                    } label: {
                        ZStack {
                            Text("Continue with Apple")
                                .font(WeepFont.bodyMedium(16))
                            HStack {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 18, weight: .medium))
                                    .padding(.leading, 20)
                                Spacer()
                            }
                        }
                        .frame(height: 54)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .background(Capsule().fill(WeepColor.buttonPrimary))
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)

                    Button {
                        signIn { try await clerk.auth.signInWithOAuth(provider: .google) }
                    } label: {
                        ZStack {
                            Text("Continue with Google")
                                .font(WeepFont.bodyMedium(16))
                            HStack {
                                Image("GoogleLogo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 18, height: 18)
                                    .padding(.leading, 20)
                                Spacer()
                            }
                        }
                        .frame(height: 54)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(WeepColor.textPrimary)
                        .background(Capsule().strokeBorder(WeepColor.cardBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func signIn(action: @escaping () async throws -> Void) {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await action()
            } catch {
                let desc = "\(error)"
                if !desc.lowercased().contains("cancel") {
                    errorMessage = "Something went wrong. Please try again."
                }
            }
            isLoading = false
        }
    }
}

// MARK: - Home

struct HomeView: View {
    @Environment(Clerk.self) private var clerk

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

                if let user = clerk.user {
                    Text("Signed in as \(user.firstName ?? user.primaryEmailAddress?.emailAddress ?? "User")")
                        .font(WeepFont.caption(13))
                        .foregroundColor(WeepColor.accent)
                        .padding(.top, 8)

                    Button("Sign out") {
                        Task {
                            try? await clerk.auth.signOut()
                        }
                    }
                    .font(WeepFont.caption(14))
                    .foregroundColor(WeepColor.textSecondary)
                    .padding(.top, 4)
                }
            }
        }
    }
}
