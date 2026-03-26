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
                    withAnimation(.easeInOut(duration: 0.4)) {
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
                HomeView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: onboardingDone)
        .animation(.easeInOut(duration: 0.3), value: clerk.isLoaded)
        .animation(.easeInOut(duration: 0.3), value: clerk.user?.id)
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

                VStack(spacing: 12) {
                    Text("Welcome back")
                        .font(WeepFont.largeTitle(32))
                        .foregroundColor(WeepColor.textPrimary)

                    Text("Sign in to continue")
                        .font(WeepFont.body(16))
                        .foregroundColor(WeepColor.textSecondary)
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
                        ZStack {
                            Text("Continue with Apple")
                                .font(WeepFont.bodyMedium(16))
                            HStack {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 18, weight: .medium))
                                    .padding(.leading, 20)
                                Spacer()
                            }
                        }
                        .frame(height: 54)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .background(Capsule().fill(WeepColor.buttonPrimary))
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)

                    Button {
                        signIn { try await clerk.auth.signInWithOAuth(provider: .google) }
                    } label: {
                        ZStack {
                            Text("Continue with Google")
                                .font(WeepFont.bodyMedium(16))
                            HStack {
                                Image("GoogleLogo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 18, height: 18)
                                    .padding(.leading, 20)
                                Spacer()
                            }
                        }
                        .frame(height: 54)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(WeepColor.textPrimary)
                        .background(Capsule().strokeBorder(WeepColor.cardBorder, lineWidth: 1))
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

struct HomeView: View {
    @Environment(Clerk.self) private var clerk
    @State private var store = KitchenStore.shared
    @State private var showCamera = false
    @State private var selectedItem: FoodItem?

    private var freshCount: Int { store.items.filter { $0.freshnessStatus == .veryFresh || $0.freshnessStatus == .fresh }.count }
    private var expiringCount: Int { store.items.filter { $0.freshnessStatus == .expiringSoon }.count }
    private var expiredCount: Int { store.items.filter { $0.freshnessStatus == .expired }.count }
    private var freshnessRatio: Double {
        guard !store.items.isEmpty else { return 1.0 }
        return Double(freshCount) / Double(store.items.count)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            WeepColor.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    weekStrip
                        .padding(.top, 8)

                    if store.items.isEmpty {
                        emptyState
                    } else {
                        overviewCard
                            .padding(.top, 20)
                        statCards
                            .padding(.top, 12)
                        recentlyAddedSection
                            .padding(.top, 28)
                    }

                    Spacer().frame(height: 100)
                }
            }

            // Floating + button
            Button {
                WeepHaptics.light()
                showCamera = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(WeepColor.buttonPrimary))
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
            }
            .padding(.trailing, 24)
            .padding(.bottom, 24)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView(
                onComplete: { item in
                    store.addItem(item)
                    showCamera = false
                },
                onDismiss: { showCamera = false }
            )
        }
        .sheet(item: $selectedItem) { item in
            ProductDetailSheet(item: item)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            Text("My Kitchen")
                .font(WeepFont.largeTitle(26))
                .foregroundColor(WeepColor.textPrimary)

            Spacer()

            if !store.items.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "refrigerator.fill")
                        .font(.system(size: 13))
                    Text("\(store.items.count)")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(WeepColor.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(WeepColor.cardBackground)
                        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                )
            }

            Menu {
                Button { Task { try? await clerk.auth.signOut() } } label: {
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                Image(systemName: "person.circle")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(WeepColor.textSecondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    // MARK: - Week Strip

    private var weekStrip: some View {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!

        return HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { offset in
                let day = calendar.date(byAdding: .day, value: offset, to: startOfWeek)!
                let isToday = calendar.isDateInToday(day)
                let dayLetter = day.formatted(.dateTime.weekday(.short)).uppercased()
                let dayNum = calendar.component(.day, from: day)

                VStack(spacing: 6) {
                    Text(dayLetter)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(isToday ? WeepColor.accent : WeepColor.textSecondary)
                    Text("\(dayNum)")
                        .font(.system(size: 16, weight: isToday ? .bold : .medium))
                        .foregroundColor(isToday ? .white : WeepColor.textPrimary)
                        .frame(width: 34, height: 34)
                        .background(
                            Circle()
                                .fill(isToday ? WeepColor.accent : Color.clear)
                        )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
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
                ratio: store.items.isEmpty ? 0 : Double(expiringCount) / Double(store.items.count)
            )
            statCard(
                value: "\(expiredCount)",
                label: "Expired",
                color: WeepColor.alertRed,
                icon: "xmark.circle.fill",
                ratio: store.items.isEmpty ? 0 : Double(expiredCount) / Double(store.items.count)
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
        VStack(alignment: .leading, spacing: 10) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(WeepColor.textPrimary)
            Text(label)
                .font(WeepFont.caption(13))
                .foregroundColor(WeepColor.textSecondary)

            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 6)
                    .frame(width: 44, height: 44)
                Circle()
                    .trim(from: 0, to: min(ratio, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(WeepColor.cardBackground)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
        )
    }

    // MARK: - Recently Added

    private var recentlyAddedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recently added")
                .font(WeepFont.headline(20))
                .foregroundColor(WeepColor.textPrimary)
                .padding(.horizontal, 24)

            LazyVStack(spacing: 12) {
                ForEach(store.items.prefix(10)) { item in
                    Button { selectedItem = item } label: {
                        FoodItemCard(item: item)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                }
            }
        }
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
                        if let f = n.totalFat { macroChip(icon: "drop.fill", value: f, color: Color(hex: 0x5B9BD5)) }
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
