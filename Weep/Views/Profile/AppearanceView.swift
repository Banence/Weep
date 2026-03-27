import SwiftUI

struct AppearanceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var themeManager = ThemeManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    themeSection
                        .padding(.top, 8)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(.label))
                    }
                }
            }
        }
    }

    // MARK: - Theme Section

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("iOS app theme")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(.label))

            HStack(spacing: 12) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    themeCard(theme)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
            )
        }
    }

    // MARK: - Theme Card

    private func themeCard(_ theme: AppTheme) -> some View {
        let isSelected = themeManager.currentTheme == theme

        return Button {
            WeepHaptics.selection()
            withAnimation(.easeInOut(duration: 0.2)) {
                themeManager.currentTheme = theme
            }
        } label: {
            VStack(spacing: 10) {
                mockupPhone(theme: theme, isSelected: isSelected)

                HStack(spacing: 5) {
                    Image(systemName: theme.icon)
                        .font(.system(size: 12, weight: .medium))
                    Text(theme.label)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                }
                .foregroundStyle(isSelected ? Color(.label) : Color(.tertiaryLabel))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Phone Mockup

    private func mockupPhone(theme: AppTheme, isSelected: Bool) -> some View {
        phoneBody(theme)
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color(.label) : Color(.separator).opacity(0.5),
                        lineWidth: isSelected ? 2.5 : 0.5
                    )
            )
    }

    @ViewBuilder
    private func phoneBody(_ theme: AppTheme) -> some View {
        if theme == .system {
            // Split: left half light, right half dark
            let light = palette(.light)
            let dark = palette(.dark)

            phoneInterior(light)
                .overlay(
                    phoneInterior(dark)
                        .mask(
                            HStack(spacing: 0) {
                                Color.clear
                                Color.black
                            }
                        )
                )
        } else {
            phoneInterior(palette(theme))
        }
    }

    private func phoneInterior(_ p: Palette) -> some View {
        VStack(spacing: 0) {
            // Notch / status bar
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(p.subtle)
                    .frame(width: 14, height: 2)
                Spacer()
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .fill(p.subtle)
                        .frame(width: 8, height: 2)
                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .fill(p.subtle)
                        .frame(width: 5, height: 2)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)

            // Three progress rings
            HStack(spacing: 8) {
                progressRing(color: Color(hex: 0xF4A261), bg: p.ringTrack, value: 0.4, size: 22)
                progressRing(color: Color(hex: 0x34C759), bg: p.ringTrack, value: 0.75, size: 22)
                progressRing(color: Color(hex: 0x7B9ECF), bg: p.ringTrack, value: 0.6, size: 22)
            }
            .padding(.top, 10)

            Spacer().frame(height: 10)

            // Content card
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(p.line)
                    .frame(width: 36, height: 4)
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(p.lineFaint)
                    .frame(height: 3)
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(p.lineFaint)
                    .frame(width: 44, height: 3)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(p.card)
            )
            .padding(.horizontal, 8)

            Spacer().frame(height: 6)

            // Bottom nav dots
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(p.subtle)
                        .frame(width: 3, height: 3)
                }
            }
            .padding(.bottom, 8)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(p.bg)
    }

    // MARK: - Progress Ring

    private func progressRing(color: Color, bg: Color, value: Double, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(bg, lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: value)
                .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }

    // MARK: - Palette

    private struct Palette {
        let bg: Color
        let card: Color
        let line: Color
        let lineFaint: Color
        let subtle: Color
        let ringTrack: Color
    }

    private func palette(_ theme: AppTheme) -> Palette {
        switch theme {
        case .light:
            return Palette(
                bg: Color(hex: 0xF2F2F7),
                card: .white,
                line: Color(hex: 0xC7C7CC),
                lineFaint: Color(hex: 0xD1D1D6),
                subtle: Color(hex: 0xC7C7CC),
                ringTrack: Color(hex: 0xE5E5EA)
            )
        case .dark:
            return Palette(
                bg: Color(hex: 0x1C1C1E),
                card: Color(hex: 0x2C2C2E),
                line: Color(hex: 0x48484A),
                lineFaint: Color(hex: 0x3A3A3C),
                subtle: Color(hex: 0x48484A),
                ringTrack: Color(hex: 0x38383A)
            )
        case .system:
            return Palette(
                bg: Color(hex: 0xE5E5EA),
                card: Color(hex: 0xD1D1D6),
                line: Color(hex: 0xAEAEB2),
                lineFaint: Color(hex: 0xC7C7CC),
                subtle: Color(hex: 0xAEAEB2),
                ringTrack: Color(hex: 0xD1D1D6)
            )
        }
    }
}
