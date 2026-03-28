import SwiftUI

struct SelectionCard: View {
    let title: String
    var subtitle: String = ""
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            WeepHaptics.selection()
            action()
        }) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: subtitle.isEmpty ? 0 : 3) {
                    Text(title)
                        .font(WeepFont.body())
                        .foregroundColor(WeepColor.textPrimary)

                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(WeepFont.caption(14))
                            .foregroundColor(WeepColor.textSecondary)
                    }
                }

                Spacer()

                // Checkbox
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? WeepColor.textPrimary : Color.clear)
                    .frame(width: 24, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(
                                isSelected ? WeepColor.textPrimary : Color(.secondaryLabel),
                                lineWidth: 1.5
                            )
                    )
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(.systemBackground))
                            .opacity(isSelected ? 1 : 0)
                    )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(WeepColor.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isSelected ? WeepColor.textPrimary : WeepColor.cardBorder,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .animation(.snappy(duration: 0.15), value: isSelected)
    }
}

struct ChipView: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            WeepHaptics.selection()
            action()
        }) {
            Text(title)
                .font(WeepFont.caption(14))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .foregroundColor(isSelected ? .white : WeepColor.textPrimary)
                .background(
                    Capsule()
                        .fill(isSelected ? WeepColor.textPrimary : WeepColor.cardBackground)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? WeepColor.textPrimary : WeepColor.cardBorder,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle())
        .animation(.snappy(duration: 0.15), value: isSelected)
    }
}
