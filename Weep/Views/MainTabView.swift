import SwiftUI
import ClerkKit

enum AppTab: Int, Hashable {
    case kitchen
    case planner
    case history
    case profile
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .kitchen
    @State private var showCamera = false
    @State private var showExpiryCheckIn = false
    @State private var store = KitchenStore.shared

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                Tab("Kitchen", systemImage: "house.fill", value: .kitchen) {
                    HomeView()
                }

                Tab("Planner", systemImage: "frying.pan.fill", value: .planner) {
                    MealPlannerView()
                }

                Tab("History", systemImage: "clock.arrow.circlepath", value: .history) {
                    HistoryView()
                }

                Tab("Profile", systemImage: "person.fill", value: .profile) {
                    ProfileView()
                }
            }
            .tint(WeepColor.accent)

            // Floating action button — only on Kitchen tab
            if selectedTab == .kitchen {
                Button {
                    WeepHaptics.medium()
                    showCamera = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 58, height: 58)
                        .background(
                            Circle()
                                .fill(WeepColor.accent)
                        )
                        .shadow(color: WeepColor.accent.opacity(0.3), radius: 10, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 72)
                .transition(.scale.combined(with: .opacity))
                .animation(.snappy(duration: 0.2), value: selectedTab)
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView(
                onComplete: { item in
                    KitchenStore.shared.addItem(item)
                    showCamera = false
                },
                onDismiss: { showCamera = false }
            )
        }
        .sheet(isPresented: $showExpiryCheckIn) {
            ExpiryCheckInSheet()
        }
        .task {
            // Wait for Clerk auth to be ready before syncing
            while Clerk.shared.user == nil {
                try? await Task.sleep(for: .milliseconds(200))
                if Task.isCancelled { return }
            }

            // Sync all data from Supabase
            async let kitchenSync: () = store.syncWithRemote()
            async let themeSync: () = ThemeManager.shared.loadThemeFromSupabase()
            _ = await (kitchenSync, themeSync)

            // Start listening for realtime changes
            await store.startRealtimeSync()

            // Check for urgent items AFTER sync completes
            let hasUrgentItems = store.activeItems.contains { item in
                guard let days = item.daysUntilExpiry else { return false }
                return days <= 2
            }
            guard hasUrgentItems else { return }

            let lastShown = UserDefaults.standard.double(forKey: "expiry_checkin_last_shown")
            let now = Date().timeIntervalSince1970
            guard lastShown < now - 86400 else { return }

            try? await Task.sleep(for: .milliseconds(800))
            showExpiryCheckIn = true
            UserDefaults.standard.set(now, forKey: "expiry_checkin_last_shown")
        }
    }
}

