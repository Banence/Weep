import SwiftUI
import ClerkKit
import UserNotifications

@main
struct WeepApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: WeepAppDelegate

    init() {
        Clerk.configure(publishableKey: "pk_test_Y2hhbXBpb24tdnVsdHVyZS0xMy5jbGVyay5hY2NvdW50cy5kZXYk")
        clearStaleSession()
        NotificationManager.registerCategories()
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
            .animation(.easeOut(duration: 0.3), value: showSplash)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    showSplash = false
                }
                // Reschedule notifications on every app launch to stay in sync
                NotificationManager.rescheduleAll(items: KitchenStore.shared.activeItems)
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

// MARK: - App Delegate (Notification Handling)

class WeepAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Show notifications even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    // Handle notification actions
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo

        switch response.actionIdentifier {
        case "MARK_USED":
            if let idString = userInfo["itemId"] as? String,
               let id = UUID(uuidString: idString),
               let item = KitchenStore.shared.activeItems.first(where: { $0.id == id }) {
                KitchenStore.shared.removeItem(item, reason: .used)
            }

        case "SNOOZE_1D":
            if let idString = userInfo["itemId"] as? String,
               let id = UUID(uuidString: idString),
               let item = KitchenStore.shared.activeItems.first(where: { $0.id == id }) {
                // Schedule a one-off reminder for tomorrow at 9 AM
                let content = UNMutableNotificationContent()
                content.title = "Reminder: \(item.name)"
                content.body = "You snoozed this yesterday — don't forget to use \(item.name)!"
                content.sound = .default
                content.interruptionLevel = .timeSensitive
                content.threadIdentifier = "expiry-\(item.id.uuidString)"

                var components = Calendar.current.dateComponents(
                    [.year, .month, .day],
                    from: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                )
                components.hour = 9
                components.minute = 0

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "snooze-\(item.id.uuidString)",
                    content: content,
                    trigger: trigger
                )
                try? await UNUserNotificationCenter.current().add(request)
            }

        default:
            break
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
