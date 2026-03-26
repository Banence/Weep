import SwiftUI
import ClerkKit

@main
struct WeepApp: App {
    init() {
        Clerk.configure(publishableKey: "pk_test_Y2hhbXBpb24tdnVsdHVyZS0xMy5jbGVyay5hY2NvdW50cy5kZXYk")
        clearStaleSession()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(Clerk.shared)
        }
    }

    /// Validates the current session on launch.
    /// If the session was deleted server-side, signs out locally
    /// so the user is routed to the sign-in screen.
    private func clearStaleSession() {
        Task {
            do {
                _ = try await Clerk.shared.auth.getToken()
            } catch {
                // Session is invalid — force sign out.
                // Even if signOut() throws (session already gone server-side),
                // the SDK reconciles its local state from the error response,
                // setting clerk.user to nil and routing to SignedOutView.
                try? await Clerk.shared.auth.signOut()
            }
        }
    }
}
