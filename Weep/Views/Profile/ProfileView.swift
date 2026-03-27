import SwiftUI
import ClerkKit
import Supabase

struct ProfileView: View {
    @Environment(Clerk.self) private var clerk
    @State private var themeManager = ThemeManager.shared
    @State private var showAccountSheet = false
    @State private var showAppearanceSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showLogoutConfirmation = false
    @State private var isSigningOut = false

    private var user: ClerkKit.User? { clerk.user }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    profileHeader

                    generalSection

                    dangerSection

                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Profile")
        }
        .sheet(isPresented: $showAccountSheet) {
            AccountDetailView()
        }
        .sheet(isPresented: $showAppearanceSheet) {
            AppearanceView()
        }
        .tint(nil)
        .confirmationDialog(
            "Log out",
            isPresented: $showLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Log out", role: .destructive) {
                isSigningOut = true
                Task {
                    try? await clerk.auth.signOut()
                    isSigningOut = false
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to log out?")
        }
        .confirmationDialog(
            "Delete Account",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) {
                // Clear remote data first, then local
                let userId = user?.id
                UserDefaults.standard.removeObject(forKey: "weep_onboarding_state")
                UserDefaults.standard.removeObject(forKey: "app_theme")
                KitchenStore.shared.clearAll()
                Task {
                    if let userId {
                        let db = SupabaseService.shared.client
                        _ = try? await db.from("food_items").delete().eq("user_id", value: userId).execute()
                        _ = try? await db.from("profiles").delete().eq("user_id", value: userId).execute()
                        await SupabaseService.deleteAllProductImages(userId: userId)
                    }
                    _ = try? await user?.delete()
                    try? await clerk.auth.signOut()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action is permanent and cannot be undone. All your data will be lost.")
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            // Avatar
            Group {
                if let url = user?.imageUrl, let imageURL = URL(string: url), user?.hasImage == true {
                    AsyncImage(url: imageURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        avatarPlaceholder
                    }
                } else {
                    avatarPlaceholder
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())

            VStack(spacing: 4) {
                Text(displayName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color(.label))

                if let email = primaryEmail {
                    Text(email)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(.secondaryLabel))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        )
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle().fill(Color(.systemGray5))
            Text(initials)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(.secondaryLabel))
        }
    }

    // MARK: - General Section

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("General")

            VStack(spacing: 0) {
                settingsRow(icon: "person.fill", iconColor: Color(.systemGray), title: "Account") {
                    showAccountSheet = true
                }

                Divider()

                settingsRow(icon: "circle.lefthalf.filled", iconColor: Color(.systemPurple), title: "Appearance") {
                    showAppearanceSheet = true
                }

                Divider()

                settingsRow(icon: "bell.fill", iconColor: Color(.systemOrange), title: "Notifications") {
                    if let settingsUrl = URL(string: UIApplication.openNotificationSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
            )
        }
    }

    // MARK: - Danger Section

    private var dangerSection: some View {
        VStack(spacing: 10) {
            Button {
                showLogoutConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    if isSigningOut {
                        ProgressView()
                            .tint(Color(.label))
                    } else {
                        Text("Log out")
                            .font(.system(size: 16, weight: .medium))
                    }
                    Spacer()
                }
                .foregroundStyle(Color(.label))
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            }
            .buttonStyle(.plain)
            .disabled(isSigningOut)

            if user?.deleteSelfEnabled == true {
                Button {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Delete account")
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                    }
                    .foregroundStyle(Color(.systemRed))
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.systemRed).opacity(0.08))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color(.tertiaryLabel))
            .textCase(.uppercase)
            .padding(.leading, 4)
    }

    private func settingsRow(icon: String, iconColor: Color, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(iconColor)
                    )

                Text(title)
                    .font(.system(size: 16))
                    .foregroundStyle(Color(.label))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Computed Values

    private var displayName: String {
        let first = user?.firstName ?? ""
        let last = user?.lastName ?? ""
        let full = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
        return full.isEmpty ? (user?.username ?? "User") : full
    }

    private var initials: String {
        let first = user?.firstName?.prefix(1) ?? ""
        let last = user?.lastName?.prefix(1) ?? ""
        let combined = "\(first)\(last)"
        return combined.isEmpty ? "?" : combined.uppercased()
    }

    private var primaryEmail: String? {
        user?.emailAddresses.first?.emailAddress
    }
}
