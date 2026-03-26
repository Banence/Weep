import SwiftUI

// TODO: Add Clerk SPM package and uncomment:
// import ClerkKit

@main
struct WeepApp: App {
    init() {
        // TODO: Configure Clerk when SPM package is added:
        // Clerk.configure(publishableKey: "pk_live_xxxxx")
    }

    var body: some Scene {
        WindowGroup {
            RootView()
            // TODO: Inject Clerk environment when SDK is added:
            // .environment(Clerk.shared)
        }
    }
}
