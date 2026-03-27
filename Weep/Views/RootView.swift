import SwiftUI
import ClerkKit

struct RootView: View {
    @Environment(Clerk.self) private var clerk
    @State private var onboardingDone = OnboardingViewModel.hasCompletedOnboarding

    var body: some View {
        Group {
            if !onboardingDone {
                // Show onboarding immediately — no waiting for Clerk
                OnboardingContainerView {
                    withAnimation(.snappy(duration: 0.35)) {
                        onboardingDone = true
                    }
                }
                .transition(.opacity)
            } else if !clerk.isLoaded {
                // Only wait for Clerk after onboarding (need auth state for home vs sign-in)
                ZStack {
                    WeepColor.background.ignoresSafeArea()
                }
            } else if clerk.user == nil {
                SignedOutView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.snappy(duration: 0.35), value: onboardingDone)
        .animation(.snappy(duration: 0.25), value: clerk.isLoaded)
        .animation(.snappy(duration: 0.25), value: clerk.user?.id)
        .onChange(of: clerk.user?.id) { old, new in
            // When user is signed out (e.g. account deletion), re-check onboarding
            if old != nil && new == nil {
                onboardingDone = OnboardingViewModel.hasCompletedOnboarding
            }
        }
    }
}

// MARK: - Signed Out (returning user)

struct SignedOutView: View {
    @Environment(Clerk.self) private var clerk
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            WeepColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    Image("WeepLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)

                    VStack(spacing: 12) {
                        Text("Welcome back")
                            .font(WeepFont.largeTitle(32))
                            .foregroundColor(WeepColor.textPrimary)

                        Text("Sign in to continue")
                            .font(WeepFont.body(16))
                            .foregroundColor(WeepColor.textSecondary)
                    }
                }

                Spacer()

                VStack(spacing: 16) {
                    if let errorMessage {
                        Text(errorMessage)
                            .font(WeepFont.caption(13))
                            .foregroundColor(WeepColor.secondary)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }

                    Button {
                        signIn { try await clerk.auth.signInWithApple() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 18, weight: .medium))
                            Text("Continue with Apple")
                                .font(WeepFont.bodyMedium(16))
                        }
                        .frame(height: 54)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color(.systemBackground))
                        .background(Capsule().fill(Color(.label)))
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)

                    Button {
                        signIn { try await clerk.auth.signInWithOAuth(provider: .google) }
                    } label: {
                        HStack(spacing: 8) {
                            Image("GoogleLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 18, height: 18)
                            Text("Continue with Google")
                                .font(WeepFont.bodyMedium(16))
                        }
                        .frame(height: 54)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color(.label))
                        .background(
                            Capsule()
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func signIn(action: @escaping () async throws -> Void) {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await action()
            } catch {
                let desc = "\(error)"
                if !desc.lowercased().contains("cancel") {
                    errorMessage = "Something went wrong. Please try again."
                }
            }
            isLoading = false
        }
    }
}

// MARK: - Home

enum KitchenFilter: String, CaseIterable {
    case all = "All"
    case fresh = "Fresh"
    case expiring = "Expiring"
    case expired = "Expired"
}

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var store = KitchenStore.shared
    @State private var selectedItem: FoodItem?
    @State private var selectedFilter: KitchenFilter = .all
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var weekOffset: Int = 0

    private let calendar = Calendar.current

    /// Items relevant on the selected date (active on that day)
    private var itemsForDate: [FoodItem] {
        let day = selectedDate
        // Show items that were added on or before this day AND not yet expired by this day (or have no expiry)
        return store.items.filter { item in
            let addedDay = calendar.startOfDay(for: item.dateAdded)
            guard addedDay <= day else { return false }
            // If removed before this day, don't show
            if let removedDay = item.removedAt {
                guard calendar.startOfDay(for: removedDay) > day else { return false }
            }
            return true
        }
    }

    private var isToday: Bool {
        calendar.isDateInToday(selectedDate)
    }

    private var freshCount: Int { itemsForDate.filter { freshnessOnDate($0) == .veryFresh || freshnessOnDate($0) == .fresh }.count }
    private var expiringCount: Int { itemsForDate.filter { freshnessOnDate($0) == .expiringSoon }.count }
    private var expiredCount: Int { itemsForDate.filter { freshnessOnDate($0) == .expired }.count }
    private var freshnessRatio: Double {
        guard !itemsForDate.isEmpty else { return 1.0 }
        return Double(freshCount) / Double(itemsForDate.count)
    }

    private var filteredItems: [FoodItem] {
        switch selectedFilter {
        case .all:
            return itemsForDate
        case .fresh:
            return itemsForDate.filter { let s = freshnessOnDate($0); return s == .veryFresh || s == .fresh || s == .unknown }
        case .expiring:
            return itemsForDate.filter { freshnessOnDate($0) == .expiringSoon }
        case .expired:
            return itemsForDate.filter { freshnessOnDate($0) == .expired }
        }
    }

    /// Calculate freshness relative to selectedDate instead of today
    private func freshnessOnDate(_ item: FoodItem) -> FreshnessStatus {
        guard let expiryDate = item.expiryDate else { return .unknown }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: selectedDate), to: calendar.startOfDay(for: expiryDate)).day ?? 0
        if days < 0 { return .expired }
        if days <= 2 { return .expiringSoon }
        if days <= 5 { return .fresh }
        return .veryFresh
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    weekStrip
                        .padding(.top, 8)

                    if itemsForDate.isEmpty {
                        emptyState
                    } else {
                        overviewCard
                            .padding(.top, 20)
                        statCards
                            .padding(.top, 12)

                        // Filter picker
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(KitchenFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .animation(nil, value: selectedDate)
                        .transaction { $0.animation = nil }

                        itemsSection
                            .padding(.top, 16)
                    }

                    Spacer().frame(height: 32)
                }
            }
            .background(WeepColor.background)
            .navigationTitle("My Kitchen")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image(uiImage: UIImage(named: colorScheme == .dark ? "white-trans" : "black-trans") ?? UIImage())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !itemsForDate.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "refrigerator.fill")
                                .font(.system(size: 12))
                            Text("\(itemsForDate.count)")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(WeepColor.textSecondary)
                    }
                }
            }
        }
        .sheet(item: $selectedItem) { item in
            ProductDetailSheet(item: item)
        }
    }

    // MARK: - Week Strip

    private var weekStrip: some View {
        let today = calendar.startOfDay(for: Date())
        let baseWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let weekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: baseWeekStart)!

        return VStack(spacing: 8) {
            // Week navigation
            HStack {
                Button {
                    withAnimation(.snappy(duration: 0.2)) { weekOffset -= 1 }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(WeepColor.textSecondary)
                        .frame(width: 32, height: 32)
                }

                Spacer()

                if weekOffset == 0 {
                    Text("This Week")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(WeepColor.textPrimary)
                } else {
                    Text(weekLabel(from: weekStart))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(WeepColor.textPrimary)
                }

                Spacer()

                Button {
                    withAnimation(.snappy(duration: 0.2)) { weekOffset += 1 }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(WeepColor.textSecondary)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 20)

            // Day buttons
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { offset in
                    let day = calendar.date(byAdding: .day, value: offset, to: weekStart)!
                    let dayStart = calendar.startOfDay(for: day)
                    let isTodayDay = calendar.isDateInToday(day)
                    let isSelected = calendar.isDate(selectedDate, inSameDayAs: day)
                    let dayLetter = day.formatted(.dateTime.weekday(.short)).uppercased()
                    let dayNum = calendar.component(.day, from: day)

                    Button {
                        withAnimation(.snappy(duration: 0.2)) {
                            selectedDate = dayStart
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(dayLetter)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(isSelected ? WeepColor.accent : isTodayDay ? WeepColor.accent : WeepColor.textSecondary)
                            Text("\(dayNum)")
                                .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? .white : WeepColor.textPrimary)
                                .frame(width: 34, height: 34)
                                .background(
                                    Circle()
                                        .fill(isSelected ? WeepColor.accent : Color.clear)
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)

            // "Back to today" button when viewing another day
            if !isToday {
                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        selectedDate = today
                        weekOffset = 0
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Back to today")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(WeepColor.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(WeepColor.accent.opacity(0.1)))
                }
                .transition(.opacity)
            }
        }
        .padding(.vertical, 8)
        .animation(.snappy(duration: 0.2), value: weekOffset)
    }

    private func weekLabel(from weekStart: Date) -> String {
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
        let startMonth = weekStart.formatted(.dateTime.month(.abbreviated))
        let endMonth = weekEnd.formatted(.dateTime.month(.abbreviated))
        let startDay = calendar.component(.day, from: weekStart)
        let endDay = calendar.component(.day, from: weekEnd)
        if startMonth == endMonth {
            return "\(startMonth) \(startDay)–\(endDay)"
        }
        return "\(startMonth) \(startDay) – \(endMonth) \(endDay)"
    }

    // MARK: - Overview Card

    private var overviewCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(freshCount)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(WeepColor.textPrimary)
                Text("Items fresh")
                    .font(WeepFont.body(15))
                    .foregroundColor(WeepColor.textSecondary)
            }

            Spacer()

            // Circular progress ring
            ZStack {
                Circle()
                    .stroke(WeepColor.divider, lineWidth: 10)
                    .frame(width: 80, height: 80)
                Circle()
                    .trim(from: 0, to: freshnessRatio)
                    .stroke(WeepColor.accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                Image(systemName: "leaf.fill")
                    .font(.system(size: 20))
                    .foregroundColor(WeepColor.accent)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(WeepColor.cardBackground)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
        )
        .padding(.horizontal, 24)
    }

    // MARK: - Stat Cards

    private var statCards: some View {
        HStack(spacing: 10) {
            statCard(
                value: "\(expiringCount)",
                label: "Expiring",
                color: WeepColor.alertAmber,
                icon: "exclamationmark.triangle.fill",
                ratio: store.activeItems.isEmpty ? 0 : Double(expiringCount) / Double(store.activeItems.count)
            )
            statCard(
                value: "\(expiredCount)",
                label: "Expired",
                color: WeepColor.alertRed,
                icon: "xmark.circle.fill",
                ratio: store.activeItems.isEmpty ? 0 : Double(expiredCount) / Double(store.activeItems.count)
            )
            statCard(
                value: "\(freshCount)",
                label: "Fresh",
                color: WeepColor.accent,
                icon: "checkmark.circle.fill",
                ratio: freshnessRatio
            )
        }
        .padding(.horizontal, 24)
    }

    private func statCard(value: String, label: String, color: Color, icon: String, ratio: Double) -> some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.12), lineWidth: 5)
                    .frame(width: 48, height: 48)
                Circle()
                    .trim(from: 0, to: min(ratio, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
            }

            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(WeepColor.textPrimary)
                Text(label)
                    .font(WeepFont.caption(12))
                    .foregroundColor(WeepColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(WeepColor.cardBackground)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
        )
    }

    // MARK: - Filtered Items

    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(selectedFilter == .all ? "All Items" : selectedFilter.rawValue)
                    .font(WeepFont.headline(20))
                    .foregroundColor(WeepColor.textPrimary)

                Spacer()

                Text("\(filteredItems.count)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(WeepColor.textSecondary)
            }
            .padding(.horizontal, 24)

            if filteredItems.isEmpty {
                VStack(spacing: 8) {
                    Text("No \(selectedFilter.rawValue.lowercased()) items")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(WeepColor.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredItems) { item in
                        Button { selectedItem = item } label: {
                            FoodItemCard(item: item)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)
                        .contextMenu {
                            Button {
                                WeepHaptics.success()
                                withAnimation(.snappy(duration: 0.25)) { store.removeItem(item, reason: .used) }
                            } label: {
                                Label("Mark as used", systemImage: "checkmark.circle")
                            }

                            Button(role: .destructive) {
                                WeepHaptics.medium()
                                withAnimation(.snappy(duration: 0.25)) { store.removeItem(item, reason: .deleted) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }

    private func filterLabel(_ filter: KitchenFilter) -> String {
        filter.rawValue
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 80)

            Image(systemName: "refrigerator")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundColor(WeepColor.iconMuted)

            Text("Your kitchen is empty")
                .font(WeepFont.headline(20))
                .foregroundColor(WeepColor.textPrimary)

            Text("Tap + to snap a photo of your first product")
                .font(WeepFont.caption(15))
                .foregroundColor(WeepColor.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Food Item Card (Cal AI style)

struct FoodItemCard: View {
    let item: FoodItem

    var body: some View {
        HStack(spacing: 0) {
            // Product image
            Group {
                if let imageData = item.productImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        WeepColor.accentLight
                        Image(systemName: "fork.knife")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(WeepColor.accent)
                    }
                }
            }
            .frame(width: 120, height: 120)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 16, bottomLeadingRadius: 16,
                    bottomTrailingRadius: 0, topTrailingRadius: 0
                )
            )

            // Info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(item.name)
                        .font(WeepFont.bodyMedium(16))
                        .foregroundColor(WeepColor.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Text(item.dateAdded, format: .dateTime.hour().minute())
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(WeepColor.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(WeepColor.background)
                        )
                }

                // Freshness
                HStack(spacing: 4) {
                    Image(systemName: item.freshnessStatus.icon)
                        .font(.system(size: 13))
                        .foregroundColor(freshnessColor)
                    Text(expiryLabel)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(WeepColor.textPrimary)
                }

                // Macro row
                if let n = item.nutrition {
                    HStack(spacing: 12) {
                        if let p = n.protein { macroChip(icon: "flame.fill", value: p, color: WeepColor.alertRed) }
                        if let c = n.totalCarbohydrates { macroChip(icon: "leaf.fill", value: c, color: WeepColor.alertAmber) }
                        if let f = n.totalFat { macroChip(icon: "drop.fill", value: f, color: WeepColor.macroFat) }
                    }
                } else if let brand = item.brand {
                    Text(brand)
                        .font(WeepFont.caption(13))
                        .foregroundColor(WeepColor.textSecondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(WeepColor.cardBackground)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
        )
    }

    private func macroChip(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(WeepColor.textPrimary)
        }
    }

    private var freshnessColor: Color {
        switch item.freshnessStatus {
        case .veryFresh: return WeepColor.accent
        case .fresh: return WeepColor.primaryGreenLight
        case .expiringSoon: return WeepColor.alertAmber
        case .expired: return WeepColor.alertRed
        case .unknown: return WeepColor.textSecondary
        }
    }

    private var expiryLabel: String {
        guard let days = item.daysUntilExpiry else { return "No date" }
        if days < 0 { return "Expired \(-days)d ago" }
        if days == 0 { return "Expires today" }
        if days == 1 { return "Tomorrow" }
        return "\(days) days left"
    }
}
