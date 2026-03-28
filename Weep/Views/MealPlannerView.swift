import SwiftUI
import ClerkKit
import Supabase
import Lottie

struct MealPlannerView: View {
    @State private var store = KitchenStore.shared
    @State private var isGenerating = false
    @State private var meals: [MealSuggestion] = []
    @State private var savedPlans: [MealPlan] = []
    @State private var selectedMeal: MealSuggestion?
    @State private var errorMessage: String?
    @State private var planToDelete: MealPlan?

    private let supabase = SupabaseService.shared.client

    private var expiringItems: [FoodItem] {
        store.activeItems
            .filter { ($0.daysUntilExpiry ?? 999) <= 3 }
            .sorted { ($0.daysUntilExpiry ?? 999) < ($1.daysUntilExpiry ?? 999) }
    }

    var body: some View {
        NavigationStack {
            List {
                    // Generate button — always visible when kitchen has items
                    if !store.activeItems.isEmpty {
                        Section {
                            generateButton
                            if let errorMessage {
                                Label(errorMessage, systemImage: "exclamationmark.triangle")
                                    .font(.system(size: 13))
                                    .foregroundStyle(WeepColor.alertAmber)
                            }
                        }
                    }

                    // Expiring items
                    if !expiringItems.isEmpty {
                        Section {
                            ForEach(expiringItems) { item in
                                expiringRow(item)
                            }
                        } header: {
                            Text("Use Soon")
                        } footer: {
                            Text("Items expiring within 3 days — prioritized in suggestions.")
                        }
                    }

                    // Current suggestions
                    if !meals.isEmpty {
                        Section("Suggested Meals") {
                            ForEach(meals) { meal in
                                Button { selectedMeal = meal } label: {
                                    mealRow(meal)
                                }
                                .tint(Color(.label))
                            }
                        }

                        Section {
                            Button {
                                Task { await savePlan() }
                            } label: {
                                Label("Save This Plan", systemImage: "bookmark")
                                    .frame(maxWidth: .infinity)
                            }
                            .tint(WeepColor.accent)
                        }
                    }

                    // Saved plans
                    ForEach(savedPlans) { plan in
                        Section {
                            ForEach(plan.meals) { meal in
                                Button { selectedMeal = meal } label: {
                                    mealRow(meal)
                                }
                                .tint(Color(.label))
                            }
                        } header: {
                            HStack {
                                Text(plan.title)
                                Spacer()
                                Text(plan.createdAt, format: .dateTime.month(.abbreviated).day())
                                    .font(.footnote)
                                    .foregroundStyle(Color(.tertiaryLabel))
                            }
                        } footer: {
                            HStack {
                                Spacer()
                                Button(role: .destructive) {
                                    planToDelete = plan
                                } label: {
                                    Label("Delete Plan", systemImage: "trash")
                                        .font(.system(size: 13))
                                }
                            }
                        }
                    }

                    // Empty state — no suggestions and no saved plans
                    if meals.isEmpty && savedPlans.isEmpty {
                        Section {
                            VStack(spacing: 16) {
                                LottieView(animation: .named("food"))
                                    .looping()
                                    .frame(width: 160, height: 160)

                                if store.activeItems.isEmpty {
                                    Text("Add items to your kitchen")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(Color(.label))

                                    Text("Once you have items in your kitchen,\nAI will suggest meals to reduce waste")
                                        .font(.system(size: 15))
                                        .foregroundStyle(Color(.secondaryLabel))
                                        .multilineTextAlignment(.center)
                                } else {
                                    Text("No meal plans yet")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(Color(.label))

                                    Text("Tap Generate to get AI-powered recipes\nthat use your items before they expire")
                                        .font(.system(size: 15))
                                        .foregroundStyle(Color(.secondaryLabel))
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .listRowBackground(Color.clear)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Meal Planner")
        }
        .fullScreenCover(isPresented: $isGenerating) {
            generatingOverlay
        }
        .sheet(item: $selectedMeal) { meal in
            RecipeDetailSheet(meal: meal, kitchenItems: store.activeItems)
        }
        .confirmationDialog(
            "Delete this meal plan?",
            isPresented: Binding(
                get: { planToDelete != nil },
                set: { if !$0 { planToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Plan", role: .destructive) {
                if let plan = planToDelete {
                    Task { await deletePlan(plan) }
                }
            }
            Button("Cancel", role: .cancel) { planToDelete = nil }
        } message: {
            Text("This plan will be permanently removed.")
        }
        .task {
            await loadSavedPlans()
        }
    }

    // MARK: - Generating Overlay

    @State private var loadingStatusIndex = 0
    private let loadingStatuses = [
        "Checking your kitchen...",
        "Finding expiring items...",
        "Creating recipes...",
        "Almost ready..."
    ]

    private var generatingOverlay: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Text("Preparing your\nmeal plan...")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color(.label))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 32)

                Spacer().frame(height: 24)

                LottieView(animation: .named("cooking"))
                    .looping()
                    .frame(height: 300)

                Spacer()

                VStack(alignment: .leading, spacing: 12) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(.tertiarySystemFill))
                                .frame(height: 6)

                            Capsule()
                                .fill(WeepColor.accent)
                                .frame(width: geo.size.width * progressFraction, height: 6)
                                .animation(.easeInOut(duration: 0.8), value: loadingStatusIndex)
                        }
                    }
                    .frame(height: 6)

                    Text(loadingStatuses[min(loadingStatusIndex, loadingStatuses.count - 1)])
                        .font(.system(size: 16))
                        .foregroundStyle(Color(.secondaryLabel))
                        .contentTransition(.numericText())
                        .animation(.snappy(duration: 0.25), value: loadingStatusIndex)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 80)
            }
        }
        .onAppear { startLoadingCycle() }
        .onDisappear { loadingStatusIndex = 0 }
    }

    private var progressFraction: CGFloat {
        CGFloat(loadingStatusIndex + 1) / CGFloat(loadingStatuses.count)
    }

    private func startLoadingCycle() {
        loadingStatusIndex = 0
        Task {
            for i in 1..<loadingStatuses.count {
                try? await Task.sleep(for: .seconds(2.5))
                if !isGenerating { return }
                withAnimation { loadingStatusIndex = i }
            }
        }
    }

    // MARK: - Components

    private func expiringRow(_ item: FoodItem) -> some View {
        HStack(spacing: 12) {
            Group {
                if let data = item.productImageData, let img = UIImage(data: data) {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    ZStack {
                        Color(.tertiarySystemFill)
                        Image(systemName: "fork.knife")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                }
            }
            .frame(width: 36, height: 36)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(item.name)
                .font(.system(size: 15))
                .lineLimit(1)

            Spacer()

            if let days = item.daysUntilExpiry {
                Text(days == 0 ? "Today" : days == 1 ? "Tomorrow" : "\(days)d")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(days <= 1 ? WeepColor.alertRed : WeepColor.alertAmber)
            }
        }
    }

    private var generateButton: some View {
        Button {
            Task { await generate() }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(WeepColor.accent.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(WeepColor.accent)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(meals.isEmpty ? "Generate Meal Plan" : "Regenerate")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(WeepColor.accent)
                    Text("\(store.activeItems.count) items · AI-powered recipes")
                        .font(.system(size: 13))
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
        }
        .disabled(isGenerating)
    }

    private func mealRow(_ meal: MealSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(meal.name)
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(.quaternaryLabel))
            }

            Text(meal.description)
                .font(.system(size: 14))
                .foregroundStyle(Color(.secondaryLabel))
                .lineLimit(2)

            HStack(spacing: 12) {
                Label(meal.cookingTime, systemImage: "clock")
                Label(meal.servings + " servings", systemImage: "person.2")
                Label(meal.difficulty, systemImage: "chart.bar")
            }
            .font(.system(size: 12))
            .foregroundStyle(Color(.tertiaryLabel))
        }
        .padding(.vertical, 4)
    }


    // MARK: - Actions

    private func generate() async {
        isGenerating = true
        errorMessage = nil

        let result = await MealPlanGenerator.generateMealPlan(from: store.activeItems)
        switch result {
        case .success(let newMeals):
            meals = newMeals
        case .failure(let error):
            errorMessage = error.message
        }
        isGenerating = false
    }

    private func savePlan() async {
        guard !meals.isEmpty, let userId = Clerk.shared.user?.id else { return }

        let plan = MealPlan(
            title: Date().formatted(.dateTime.weekday(.wide).month(.abbreviated).day()),
            meals: meals, usedItemIds: matchingItemIds()
        )

        let dto = MealPlanDTO(
            id: plan.id, userId: userId, title: plan.title,
            meals: plan.meals, usedItemIds: plan.usedItemIds, createdAt: plan.createdAt
        )

        do {
            try await supabase.from("meal_plans").insert(dto).execute()
            withAnimation(.snappy(duration: 0.25)) {
                savedPlans.insert(plan, at: 0)
                meals = []
            }
        } catch {
            print("[MealPlanner] Save failed: \(error)")
        }
    }

    private func deletePlan(_ plan: MealPlan) async {
        do {
            try await supabase.from("meal_plans").delete()
                .eq("id", value: plan.id.uuidString).execute()
            withAnimation(.snappy(duration: 0.25)) {
                savedPlans.removeAll { $0.id == plan.id }
            }
        } catch {
            print("[MealPlanner] Delete failed: \(error)")
        }
    }

    private func loadSavedPlans() async {
        guard let userId = Clerk.shared.user?.id else { return }
        do {
            let dtos: [MealPlanDTO] = try await supabase
                .from("meal_plans").select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .limit(10).execute().value
            savedPlans = dtos.map {
                MealPlan(id: $0.id ?? UUID(), title: $0.title, meals: $0.meals,
                         usedItemIds: $0.usedItemIds, createdAt: $0.createdAt ?? Date())
            }
        } catch {
            print("[MealPlanner] Load failed: \(error)")
        }
    }

    private func matchingItemIds() -> [UUID] {
        let names = Set(meals.flatMap(\.ingredients).map { $0.lowercased() })
        return store.activeItems.filter { item in
            names.contains { $0.contains(item.name.lowercased()) || item.name.lowercased().contains($0) }
        }.map(\.id)
    }
}

// MARK: - Recipe Detail Sheet

struct RecipeDetailSheet: View {
    let meal: MealSuggestion
    let kitchenItems: [FoodItem]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Description + meta stats
                Section {
                    Text(meal.description)
                        .font(.system(size: 16))
                        .foregroundStyle(Color(.secondaryLabel))
                        .listRowSeparator(.hidden)

                    HStack(spacing: 0) {
                        metaStat(icon: "clock", value: meal.cookingTime, label: "Time")
                        Divider().frame(height: 36)
                        metaStat(icon: "person.2", value: meal.servings, label: "Servings")
                        Divider().frame(height: 36)
                        metaStat(icon: "speedometer", value: meal.difficulty, label: "Level", color: difficultyColor)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowSeparator(.hidden)
                }

                // Ingredients
                Section {
                    ForEach(meal.ingredients, id: \.self) { ingredient in
                        let match = kitchenItems.first {
                            $0.name.localizedCaseInsensitiveContains(ingredient) ||
                            ingredient.localizedCaseInsensitiveContains($0.name)
                        }

                        HStack(spacing: 12) {
                            Image(systemName: match != nil ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 18))
                                .foregroundStyle(match != nil ? WeepColor.accent : Color(.quaternaryLabel))

                            Text(ingredient)
                                .font(.system(size: 16))

                            Spacer()

                            if let days = match?.daysUntilExpiry {
                                Text(days == 0 ? "Today" : days == 1 ? "Tomorrow" : "\(days)d")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(days <= 2 ? WeepColor.alertAmber : Color(.tertiaryLabel))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule().fill(days <= 2 ? WeepColor.alertAmber.opacity(0.1) : Color(.tertiarySystemFill))
                                    )
                            }
                        }
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    }
                } header: {
                    Text("Ingredients")
                } footer: {
                    Text("Basic pantry staples (salt, pepper, oil, garlic) assumed available.")
                }

                // Instructions
                if !meal.steps.isEmpty {
                    Section("Instructions") {
                        ForEach(Array(meal.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 14) {
                                Text("\(index + 1)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 26, height: 26)
                                    .background(Circle().fill(WeepColor.accent))

                                Text(cleanStep(step))
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color(.label))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 2)
                            .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(meal.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func metaStat(icon: String, value: String, label: String, color: Color = Color(.label)) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
    }

    private var difficultyColor: Color {
        switch meal.difficulty.lowercased() {
        case "easy": return WeepColor.accent
        case "medium": return WeepColor.alertAmber
        case "hard": return WeepColor.alertRed
        default: return Color(.secondaryLabel)
        }
    }

    private func cleanStep(_ step: String) -> String {
        var s = step
        if let range = s.range(of: #"^Step\s*\d+\s*[:\.\-]\s*"#, options: .regularExpression) {
            s.removeSubrange(range)
        }
        if let range = s.range(of: #"^\d+[\.\)]\s*"#, options: .regularExpression) {
            s.removeSubrange(range)
        }
        return s
    }
}
