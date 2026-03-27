import SwiftUI
import ClerkKit

@main
struct WeepApp: App {
    init() {
        Clerk.configure(publishableKey: "pk_test_Y2hhbXBpb24tdnVsdHVyZS0xMy5jbGVyay5hY2NvdW50cy5kZXYk")
        clearStaleSession()
    }

    @State private var themeManager = ThemeManager.shared
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environment(Clerk.shared)
                    .preferredColorScheme(themeManager.currentTheme.colorScheme)

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .animation(.easeOut(duration: 0.4), value: showSplash)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    showSplash = false
                }
            }
        }
    }

    private func clearStaleSession() {
        Task {
            do {
                _ = try await Clerk.shared.auth.getToken()
            } catch {
                try? await Clerk.shared.auth.signOut()
            }
        }
    }
}

// MARK: - Splash Screen

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            Image("WeepLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}
