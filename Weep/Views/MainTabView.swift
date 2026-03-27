import SwiftUI
import ClerkKit

enum AppTab: Int, Hashable {
    case kitchen
    case planner
    case insights
    case profile
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .kitchen
    @State private var showCamera = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                Tab("Kitchen", systemImage: "house.fill", value: .kitchen) {
                    HomeView()
                }

                Tab("Planner", systemImage: "book.fill", value: .planner) {
                    MealPlannerPlaceholderView()
                }

                Tab("Insights", systemImage: "chart.bar.fill", value: .insights) {
                    InsightsPlaceholderView()
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
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
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
    }
}

// MARK: - Placeholder Views

struct MealPlannerPlaceholderView: View {
    var body: some View {
        ZStack {
            WeepColor.background.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "book.fill")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundColor(WeepColor.iconMuted)

                Text("Meal Planner")
                    .font(WeepFont.headline(20))
                    .foregroundColor(WeepColor.textPrimary)

                Text("Plan your meals to reduce food waste")
                    .font(WeepFont.caption(15))
                    .foregroundColor(WeepColor.textSecondary)
            }
        }
    }
}

struct InsightsPlaceholderView: View {
    var body: some View {
        ZStack {
            WeepColor.background.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundColor(WeepColor.iconMuted)

                Text("Insights")
                    .font(WeepFont.headline(20))
                    .foregroundColor(WeepColor.textPrimary)

                Text("Waste tracking insights coming soon")
                    .font(WeepFont.caption(15))
                    .foregroundColor(WeepColor.textSecondary)
            }
        }
    }
}
