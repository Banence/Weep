import SwiftUI
import ClerkKit
import Supabase

@Observable
class OnboardingViewModel {
    // MARK: - Navigation

    var currentStep: OnboardingStep = .welcome
    let totalSteps = OnboardingStep.allCases.count

    // MARK: - Screen 2: About You

    var displayName: String = ""
    var avatarChoice: String = "default"

    // MARK: - Screen 3: Household

    var householdAdults: Int = 1
    var householdChildren: Int = 0
    var hasPets: Bool = false

    // MARK: - Screen 4: Shopping Habits

    var shoppingFrequency: ShoppingFrequency?
    var shoppingLocations: Set<ShoppingLocation> = []

    // MARK: - Screen 5: Kitchen Zones

    var storageZones: [StorageZone] = StorageZone.defaults

    // MARK: - Screen 6: Dietary

    var dietaryPreferences: Set<DietaryPreference> = []

    // MARK: - Screen 7: Waste Reality

    var selfReportedWasteLevel: Double = 0.5

    // MARK: - Screen 8: Goal

    var primaryGoal: PrimaryGoal?

    // MARK: - Screen 9: Permissions

    var cameraPermissionGranted: Bool = false
    var notificationPermissionGranted: Bool = false

    // MARK: - Screen 10: First Scan

    var firstItemAdded: Bool = false
    var firstScanSubView: Bool = false

    // MARK: - Completion

    var onboardingCompleted: Bool = false

    // MARK: - Permission Sub-Step

    var permissionSubStep: Int = 0

    // MARK: - Computed

    var progress: Double {
        guard let idx = OnboardingStep.allCases.firstIndex(of: currentStep) else { return 0 }
        return Double(idx) / Double(totalSteps - 1)
    }

    var householdSize: Int { householdAdults + householdChildren }

    var estimatedMonthlyWasteCost: Double {
        // EU average ~€60/month per person, scaled by self-reported level
        let basePerPerson = 60.0
        let scaleFactor = 0.3 + (selfReportedWasteLevel * 1.4) // range: 0.3x to 1.7x
        return Double(householdSize) * basePerPerson * scaleFactor
    }

    // MARK: - Navigation

    func advance() {
        WeepHaptics.success()
        guard let idx = OnboardingStep.allCases.firstIndex(of: currentStep),
              idx + 1 < OnboardingStep.allCases.count else { return }
        currentStep = OnboardingStep.allCases[idx + 1]
        persistToUserDefaults()
    }

    func goBack() {
        WeepHaptics.light()
        guard let idx = OnboardingStep.allCases.firstIndex(of: currentStep),
              idx - 1 >= 0 else { return }
        currentStep = OnboardingStep.allCases[idx - 1]
    }

    func skip() {
        guard currentStep.canSkip else { return }
        advance()
    }

    func complete() {
        onboardingCompleted = true
        persistToUserDefaults()
        Task { await persistToSupabase() }
    }

    // MARK: - Persistence (UserDefaults for mid-onboarding resume)

    private let persistenceKey = "weep_onboarding_state"

    func persistToUserDefaults() {
        let state: [String: Any] = [
            "currentStep": currentStep.rawValue,
            "displayName": displayName,
            "avatarChoice": avatarChoice,
            "householdAdults": householdAdults,
            "householdChildren": householdChildren,
            "hasPets": hasPets,
            "shoppingFreq": shoppingFrequency?.rawValue ?? "",
            "shoppingLocations": shoppingLocations.map(\.rawValue),
            "dietaryPreferences": dietaryPreferences.map(\.rawValue),
            "selfReportedWasteLevel": selfReportedWasteLevel,
            "primaryGoal": primaryGoal?.rawValue ?? "",
            "onboardingCompleted": onboardingCompleted,
        ]
        UserDefaults.standard.set(state, forKey: persistenceKey)
    }

    func restoreFromUserDefaults() {
        guard let state = UserDefaults.standard.dictionary(forKey: persistenceKey) else { return }

        if let stepRaw = state["currentStep"] as? Int,
           let step = OnboardingStep(rawValue: stepRaw) {
            currentStep = step
        }
        displayName = state["displayName"] as? String ?? ""
        avatarChoice = state["avatarChoice"] as? String ?? "default"
        householdAdults = state["householdAdults"] as? Int ?? 1
        householdChildren = state["householdChildren"] as? Int ?? 0
        hasPets = state["hasPets"] as? Bool ?? false

        if let freqRaw = state["shoppingFreq"] as? String, !freqRaw.isEmpty {
            shoppingFrequency = ShoppingFrequency(rawValue: freqRaw)
        }
        if let locs = state["shoppingLocations"] as? [String] {
            shoppingLocations = Set(locs.compactMap { ShoppingLocation(rawValue: $0) })
        }
        if let diets = state["dietaryPreferences"] as? [String] {
            dietaryPreferences = Set(diets.compactMap { DietaryPreference(rawValue: $0) })
        }
        selfReportedWasteLevel = state["selfReportedWasteLevel"] as? Double ?? 0.5
        if let goalRaw = state["primaryGoal"] as? String, !goalRaw.isEmpty {
            primaryGoal = PrimaryGoal(rawValue: goalRaw)
        }
        onboardingCompleted = state["onboardingCompleted"] as? Bool ?? false
    }

    static var hasCompletedOnboarding: Bool {
        guard let state = UserDefaults.standard.dictionary(forKey: "weep_onboarding_state") else { return false }
        return state["onboardingCompleted"] as? Bool ?? false
    }

    // MARK: - Supabase Persistence

    func persistToSupabase() async {
        guard let userId = Clerk.shared.user?.id else { return }

        let zoneDTOs = storageZones.map {
            StorageZoneDTO(id: $0.id.uuidString, name: $0.name, icon: $0.icon, isEnabled: $0.isEnabled)
        }

        let profile = ProfileDTO(
            id: nil,
            userId: userId,
            displayName: displayName,
            avatarChoice: avatarChoice,
            householdAdults: householdAdults,
            householdChildren: householdChildren,
            hasPets: hasPets,
            shoppingFrequency: shoppingFrequency?.rawValue,
            shoppingLocations: shoppingLocations.map(\.rawValue),
            storageZones: zoneDTOs,
            dietaryPreferences: dietaryPreferences.map(\.rawValue),
            selfReportedWasteLevel: selfReportedWasteLevel,
            primaryGoal: primaryGoal?.rawValue,
            onboardingCompleted: onboardingCompleted,
            appTheme: ThemeManager.shared.currentTheme.rawValue
        )

        do {
            try await SupabaseService.shared.client
                .from("profiles")
                .upsert(profile, onConflict: "user_id")
                .execute()
        } catch {
            print("[Onboarding] Failed to persist profile to Supabase: \(error)")
        }
    }

    func loadFromSupabase() async {
        guard let userId = Clerk.shared.user?.id else { return }

        do {
            let profiles: [ProfileDTO] = try await SupabaseService.shared.client
                .from("profiles")
                .select()
                .eq("user_id", value: userId)
                .limit(1)
                .execute()
                .value

            guard let profile = profiles.first else { return }

            await MainActor.run {
                self.displayName = profile.displayName
                self.avatarChoice = profile.avatarChoice
                self.householdAdults = profile.householdAdults
                self.householdChildren = profile.householdChildren
                self.hasPets = profile.hasPets
                self.shoppingFrequency = ShoppingFrequency(rawValue: profile.shoppingFrequency ?? "")
                self.shoppingLocations = Set(profile.shoppingLocations.compactMap { ShoppingLocation(rawValue: $0) })
                self.storageZones = profile.storageZones.map {
                    StorageZone(id: UUID(uuidString: $0.id) ?? UUID(), name: $0.name, icon: $0.icon, isEnabled: $0.isEnabled)
                }
                self.dietaryPreferences = Set(profile.dietaryPreferences.compactMap { DietaryPreference(rawValue: $0) })
                self.selfReportedWasteLevel = profile.selfReportedWasteLevel
                self.primaryGoal = PrimaryGoal(rawValue: profile.primaryGoal ?? "")
                self.onboardingCompleted = profile.onboardingCompleted
            }
        } catch {
            print("[Onboarding] Failed to load profile from Supabase: \(error)")
        }
    }
}
