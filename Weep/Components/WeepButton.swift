import SwiftUI

struct WeepButton: View {
    let title: String
    var style: Style = .primary
    var isEnabled: Bool = true
    let action: () -> Void

    enum Style {
        case primary, secondary, ghost
    }

    var body: some View {
        Button(action: {
            WeepHaptics.light()
            action()
        }) {
            Text(title)
                .font(WeepFont.bodyMedium(17))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .foregroundColor(foregroundColor)
                .background(backgroundColor)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(borderColor, lineWidth: style == .secondary ? 1 : 0)
                )
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity(isEnabled ? 1 : 0.35)
        .disabled(!isEnabled)
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return WeepColor.buttonPrimaryText
        case .secondary: return WeepColor.textPrimary
        case .ghost: return WeepColor.textSecondary
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return WeepColor.buttonPrimary
        case .secondary: return Color.clear
        case .ghost: return Color.clear
        }
    }

    private var borderColor: Color {
        switch style {
        case .secondary: return WeepColor.cardBorder
        default: return Color.clear
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(.snappy(duration: 0.12), value: configuration.isPressed)
    }
}
