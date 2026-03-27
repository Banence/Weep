import SwiftUI
import AVFoundation
import UserNotifications

struct PermissionsScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    var body: some View {
        Group {
            if viewModel.permissionSubStep == 0 {
                CameraPermissionView(
                    onAllow: { requestCameraPermission() },
                    onDefer: {
                        WeepHaptics.light()
                        withAnimation(.snappy(duration: 0.25)) {
                            viewModel.permissionSubStep = 1
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            } else {
                NotificationPermissionView(
                    onAllow: { requestNotificationPermission() },
                    onDefer: { onContinue() }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .animation(.snappy(duration: 0.25), value: viewModel.permissionSubStep)
    }

    private func requestCameraPermission() {
        WeepHaptics.light()
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                viewModel.cameraPermissionGranted = granted
                withAnimation(.snappy(duration: 0.25)) {
                    viewModel.permissionSubStep = 1
                }
            }
        }
    }

    private func requestNotificationPermission() {
        WeepHaptics.light()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                viewModel.notificationPermissionGranted = granted
                onContinue()
            }
        }
    }
}

// MARK: - Camera Permission (with illustration)

struct CameraPermissionView: View {
    let onAllow: () -> Void
    let onDefer: () -> Void

    @State private var showScanLine = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                Spacer().frame(height: 20)

                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(WeepColor.iconMuted)
                    .frame(maxWidth: .infinity)
                    .staggeredAppear(delay: 0.1)

                Spacer().frame(height: 14)

                Text("Snap & identify\nyour food")
                    .font(WeepFont.largeTitle(28))
                    .foregroundColor(WeepColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .staggeredAppear(delay: 0.2)

                Spacer().frame(height: 8)

                Text("Point your camera at any product and\nour AI will identify it instantly.")
                    .font(WeepFont.body(15))
                    .foregroundColor(WeepColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity)
                    .staggeredAppear(delay: 0.3)
            }

            Spacer().frame(height: 20)

            // Camera illustration
            CameraIllustration(showScanLine: showScanLine)
                .padding(.horizontal, 32)
                .staggeredAppear(delay: 0.35)

            Spacer()

            // Buttons
            permissionButtons(title: "Allow Camera", onAllow: onAllow, onDefer: onDefer)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(1.0)) {
                showScanLine = true
            }
        }
    }
}

// MARK: - Camera Illustration

struct CameraIllustration: View {
    let showScanLine: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Viewfinder
            ZStack {
                // Soft background
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.tertiarySystemGroupedBackground))

                // Product image
                AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=400&h=300&fit=crop")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color(.systemGray5)
                }
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(8)
                .opacity(0.85)

                // Viewfinder corners
                GeometryReader { geo in
                    let s: CGFloat = 24
                    let w: CGFloat = 3
                    let inset: CGFloat = 24

                    ForEach(0..<4, id: \.self) { corner in
                        let isRight = corner % 2 == 1
                        let isBottom = corner >= 2
                        let x = isRight ? geo.size.width - inset : inset
                        let y = isBottom ? geo.size.height - inset : inset

                        Path { p in
                            p.move(to: CGPoint(x: x + (isRight ? -s : s), y: y))
                            p.addLine(to: CGPoint(x: x, y: y))
                            p.addLine(to: CGPoint(x: x, y: y + (isBottom ? -s : s)))
                        }
                        .stroke(Color.white, lineWidth: w)
                    }
                }

                // Scan line
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(WeepColor.accent)
                        .frame(width: geo.size.width - 56, height: 2)
                        .frame(maxWidth: .infinity)
                        .offset(y: showScanLine ? geo.size.height * 0.65 : geo.size.height * 0.3)
                        .opacity(0.7)
                }
            }
            .frame(height: 176)

            Spacer().frame(height: 10)

            // Result card
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=100&h=100&fit=crop")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color(.systemGray5)
                }
                .frame(width: 38, height: 38)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Organic Carrots")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(WeepColor.textPrimary)

                    Text("Added · Expires in ~7 days")
                        .font(.system(size: 12))
                        .foregroundColor(WeepColor.textSecondary)
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(WeepColor.accent)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(WeepColor.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(WeepColor.cardBorder, lineWidth: 1)
            )
        }
    }
}

// MARK: - Notification Permission

struct NotificationPermissionView: View {
    let onAllow: () -> Void
    let onDefer: () -> Void

    @State private var showNotif1 = false
    @State private var showNotif2 = false
    @State private var showNotif3 = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                Spacer().frame(height: 20)

                Image(systemName: "bell.fill")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(WeepColor.iconMuted)
                    .symbolEffect(.wiggle.byLayer, options: .repeat(.periodic(delay: 5.0)))
                    .frame(maxWidth: .infinity)
                    .staggeredAppear(delay: 0.1)

                Spacer().frame(height: 14)

                Text("Never let food\ngo to waste")
                    .font(WeepFont.largeTitle(28))
                    .foregroundColor(WeepColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .staggeredAppear(delay: 0.2)

                Spacer().frame(height: 8)

                Text("Get updates on expiring items and\nreminders to use your food in time.")
                    .font(WeepFont.body(15))
                    .foregroundColor(WeepColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity)
                    .staggeredAppear(delay: 0.3)
            }

            Spacer().frame(height: 16)

            // Phone with notifications inside
            PhoneIllustration(
                showNotif1: showNotif1,
                showNotif2: showNotif2,
                showNotif3: showNotif3
            )
            .padding(.horizontal, 28)
            .staggeredAppear(delay: 0.35)

            Spacer()

            // Buttons
            permissionButtons(title: "Enable notifications", onAllow: onAllow, onDefer: onDefer)
        }
        .onAppear {
            withAnimation(.snappy(duration: 0.35).delay(0.8)) { showNotif1 = true }
            withAnimation(.snappy(duration: 0.35).delay(1.5)) { showNotif2 = true }
            withAnimation(.snappy(duration: 0.35).delay(2.2)) { showNotif3 = true }
        }
    }
}

// MARK: - Shared buttons

private func permissionButtons(title: String, onAllow: @escaping () -> Void, onDefer: @escaping () -> Void) -> some View {
    VStack(spacing: 0) {
        WeepButton(title: title) { onAllow() }
            .padding(.horizontal, 24)

        Button("Maybe later") { onDefer() }
            .font(WeepFont.body(15))
            .foregroundColor(WeepColor.textSecondary)
            .frame(height: 52)
    }
    .padding(.bottom, 4)
}

// MARK: - Phone Illustration (Notifications)

struct PhoneIllustration: View {
    let showNotif1: Bool
    let showNotif2: Bool
    let showNotif3: Bool

    private let gridColor = Color(.systemGray4)
    private let phoneColor = Color(.secondarySystemGroupedBackground)

    var body: some View {
        VStack(spacing: 0) {
            // Notifications
            VStack(spacing: 6) {
                if showNotif1 {
                    notifBanner(
                        title: "Your yogurt expires tomorrow",
                        body: "Don't let it go to waste — maybe a smoothie?",
                        time: "now",
                        imageURL: "https://images.unsplash.com/photo-1488477181946-6428a0291777?w=100&h=100&fit=crop"
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
                }

                if showNotif2 {
                    notifBanner(
                        title: "Milk expires today",
                        body: "Use it in your morning coffee or cereal",
                        time: "1h ago",
                        imageURL: "https://images.unsplash.com/photo-1563636619-e9143da7973b?w=100&h=100&fit=crop"
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
                }

                if showNotif3 {
                    notifBanner(
                        title: "Bananas are going brown",
                        body: "Make banana bread before they go bad!",
                        time: "2m ago",
                        imageURL: "https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=100&h=100&fit=crop"
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 14)
            .padding(.bottom, 8)

            // App grid
            VStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(0..<4, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(gridColor)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                    .opacity(row == 2 ? 0.4 : 0.7)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(phoneColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color(.separator), lineWidth: 1)
        )
    }

    private func notifBanner(title: String, body: String, time: String, imageURL: String) -> some View {
        HStack(alignment: .center, spacing: 10) {
            AsyncImage(url: URL(string: imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(WeepColor.accent.opacity(0.1))
                    .overlay(
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(WeepColor.accent)
                    )
            }
            .frame(width: 36, height: 36)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(WeepColor.textPrimary)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    Text(time)
                        .font(.system(size: 11))
                        .foregroundColor(WeepColor.textSecondary)
                }

                Text(body)
                    .font(.system(size: 11.5))
                    .foregroundColor(WeepColor.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}
