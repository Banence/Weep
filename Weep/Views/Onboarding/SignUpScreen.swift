import SwiftUI
import ClerkKit

struct SignUpScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @Environment(Clerk.self) private var clerk
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var didComplete = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Header
            VStack(spacing: 12) {
                Text("Create your\naccount")
                    .font(WeepFont.largeTitle(32))
                    .foregroundColor(WeepColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .staggeredAppear(delay: 0.1)

                Text("Sign up to save your progress\nand sync across devices")
                    .font(WeepFont.body(16))
                    .foregroundColor(WeepColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .staggeredAppear(delay: 0.2)
            }

            Spacer()

            // Bottom: error + buttons + terms
            VStack(spacing: 16) {
                if let errorMessage {
                    Text(errorMessage)
                        .font(WeepFont.caption(13))
                        .foregroundColor(WeepColor.secondary)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }

                // Continue with Apple
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
                .staggeredAppear(delay: 0.3)

                // Continue with Google
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
                .staggeredAppear(delay: 0.35)

                // Terms
                Text("By continuing, you agree to our\nTerms of Service and Privacy Policy")
                    .font(WeepFont.caption(13))
                    .foregroundColor(WeepColor.iconMuted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
                    .staggeredAppear(delay: 0.4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .onChange(of: clerk.user?.id) { _, newId in
            if newId != nil, !didComplete {
                handleAuthSuccess()
            }
        }
        .onAppear {
            // If already signed in (existing session), skip auth
            if clerk.user != nil, !didComplete {
                handleAuthSuccess()
            }
        }
    }

    private func signIn(action: @escaping () async throws -> Void) {
        guard !isLoading, !didComplete else { return }
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await action()
                // Auth completed synchronously — user should be set
                if clerk.user != nil, !didComplete {
                    handleAuthSuccess()
                }
                // Otherwise onChange will catch it
            } catch {
                isLoading = false
                let desc = "\(error)"
                // If session already exists, treat as success
                if desc.contains("session_exists") || desc.contains("already signed in") {
                    if clerk.user != nil, !didComplete {
                        handleAuthSuccess()
                    }
                } else if !desc.lowercased().contains("cancel") {
                    errorMessage = "Something went wrong. Please try again."
                }
            }
        }
    }

    private func handleAuthSuccess() {
        guard !didComplete else { return }
        didComplete = true
        isLoading = false
        WeepHaptics.success()

        if let user = clerk.user {
            viewModel.displayName = user.firstName ?? user.username ?? "there"
        }

        onContinue()
    }
}
