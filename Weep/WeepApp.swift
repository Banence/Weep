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

    /// Clears any stale Clerk session from the Keychain on launch.
    /// This prevents 404 errors when a session was deleted server-side
    /// but the local device still has it cached.
    private func clearStaleSession() {
        Task {
            do {
                _ = try await Clerk.shared.auth.getToken()
            } catch {
                let desc = "\(error)"
                if desc.contains("resource_not_found") || desc.contains("Session not found") {
                    try? await Clerk.shared.auth.signOut()
                }
            }
        }
    }
}
