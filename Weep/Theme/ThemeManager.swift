import SwiftUI
import ClerkKit
import Supabase

enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "app_theme")
            Task { await persistThemeToSupabase() }
        }
    }

    private init() {
        let stored = UserDefaults.standard.string(forKey: "app_theme") ?? AppTheme.system.rawValue
        self.currentTheme = AppTheme(rawValue: stored) ?? .system
    }

    func loadThemeFromSupabase() async {
        guard let userId = Clerk.shared.user?.id else { return }
        do {
            let profiles: [ProfileDTO] = try await SupabaseService.shared.client
                .from("profiles")
                .select()
                .eq("user_id", value: userId)
                .limit(1)
                .execute()
                .value

            if let theme = profiles.first?.appTheme,
               let appTheme = AppTheme(rawValue: theme) {
                await MainActor.run {
                    self.currentTheme = appTheme
                    UserDefaults.standard.set(appTheme.rawValue, forKey: "app_theme")
                }
            }
        } catch {
            print("[ThemeManager] Failed to load theme from Supabase: \(error)")
        }
    }

    private func persistThemeToSupabase() async {
        guard let userId = Clerk.shared.user?.id else { return }
        do {
            try await SupabaseService.shared.client
                .from("profiles")
                .update(["app_theme": currentTheme.rawValue])
                .eq("user_id", value: userId)
                .execute()
        } catch {
            print("[ThemeManager] Failed to persist theme to Supabase: \(error)")
        }
    }
}
