import SwiftUI
import CoreHaptics

// MARK: - Colors

enum WeepColor {
    // Core palette
    static let primaryGreen = Color(hex: 0x2D6A4F)
    static let primaryGreenLight = Color(hex: 0x40916C)
    static let accentWarm = Color(hex: 0xE9C46A)
    static let alertAmber = Color(hex: 0xF4A261)
    static let alertRed = Color(hex: 0xE76F51)

    // Surfaces
    static let background = Color(hex: 0xF7F6F3)
    static let cardBackground = Color.white
    static let cardBorder = Color(hex: 0xE8E6E1)

    // Text
    static let textPrimary = Color(hex: 0x1A1A1A)
    static let textSecondary = Color(hex: 0x9B9B9B)

    // Button
    static let buttonPrimary = Color(hex: 0x1A1A1A)
    static let buttonPrimaryText = Color.white

    // Accent — vibrant green (selected states, toggles, tags)
    static let accent = Color(hex: 0x34C759)
    static let accentLight = Color(hex: 0xDAF5E4)

    // Secondary — warm terracotta (secondary highlights)
    static let secondary = Color(hex: 0xE07A5F)
    static let secondaryLight = Color(hex: 0xFDE8E2)

    // Subtle
    static let iconMuted = Color(hex: 0xC5C3BE)
    static let divider = Color(hex: 0xEDEBE7)
    static let placeholder = Color(hex: 0xA8A8A8)
}

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Typography

enum WeepFont {
    static func largeTitle(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }

    static func headline(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    static func body(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func bodyMedium(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    static func caption(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func stat(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .monospaced)
    }
}

// MARK: - Haptics

enum WeepHaptics {
    private static let supportsHaptics: Bool = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    static func light() {
        guard supportsHaptics else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        guard supportsHaptics else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        guard supportsHaptics else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func selection() {
        guard supportsHaptics else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

// MARK: - Staggered Animation

struct StaggeredAppearModifier: ViewModifier {
    let delay: Double
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func staggeredAppear(delay: Double) -> some View {
        modifier(StaggeredAppearModifier(delay: delay))
    }
}

// MARK: - Bottom Safe Area Button

struct BottomButtonBar<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .padding(.top, 12)
    }
}
