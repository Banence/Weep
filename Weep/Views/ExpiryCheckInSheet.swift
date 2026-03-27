import SwiftUI

struct ExpiryCheckInSheet: View {
    @State private var store = KitchenStore.shared
    @State private var removedIDs: Set<UUID> = []
    @Environment(\.dismiss) private var dismiss

    private var urgentItems: [FoodItem] {
        store.activeItems.filter { item in
            guard let days = item.daysUntilExpiry else { return false }
            return days <= 2
        }
        .sorted { ($0.daysUntilExpiry ?? 0) < ($1.daysUntilExpiry ?? 0) }
    }

    private var visibleItems: [FoodItem] {
        urgentItems.filter { !removedIDs.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Drag indicator
            Capsule()
                .fill(Color(.systemFill))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 8)

            if visibleItems.isEmpty {
                allClearedView
            } else {
                // Header
                VStack(spacing: 2) {
                    Text("\(visibleItems.count) item\(visibleItems.count == 1 ? "" : "s") expiring soon")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(.label))

                    Text("Tap to mark as used")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(.secondaryLabel))
                }

                // Items
                VStack(spacing: 6) {
                    ForEach(visibleItems) { item in
                        itemRow(item)
                    }
                }
                .padding(.horizontal, 20)
            }

            // Button
            Button {
                for id in removedIDs {
                    if let item = store.activeItems.first(where: { $0.id == id }) {
                        store.removeItem(item, reason: .used)
                    }
                }
                dismiss()
            } label: {
                Text(removedIDs.isEmpty ? "Looks good" : "Done")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(removedIDs.isEmpty ? Color(.label) : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(removedIDs.isEmpty ? Color(.tertiarySystemFill) : WeepColor.accent)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .animation(.snappy(duration: 0.15), value: removedIDs.isEmpty)
        }
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
        .interactiveDismissDisabled(false)
    }

    private var sheetHeight: CGFloat {
        if visibleItems.isEmpty {
            return 250
        }
        // Drag(21) + gap(8) + header(~50) + gap(16) + items(68 each) + gap(16) + button(~72)
        let itemsHeight = CGFloat(min(visibleItems.count, 5)) * 68
        return 200 + itemsHeight
    }

    // MARK: - Item Row

    private func itemRow(_ item: FoodItem) -> some View {
        Button {
            WeepHaptics.light()
            _ = withAnimation(.snappy(duration: 0.25)) {
                removedIDs.insert(item.id)
            }
        } label: {
            HStack(spacing: 12) {
                // Thumbnail
                Group {
                    if let data = item.productImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ZStack {
                            Color(.tertiarySystemFill)
                            Image(systemName: "fork.knife")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(.tertiaryLabel))
                        }
                    }
                }
                .frame(width: 42, height: 42)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color(.label))
                        .lineLimit(1)

                    Text(expiryLabel(for: item))
                        .font(.system(size: 13))
                        .foregroundStyle(expiryColor(for: item))
                }

                Spacer(minLength: 0)

                Image(systemName: "checkmark.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(.quaternaryLabel))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
        .transition(.asymmetric(
            insertion: .identity,
            removal: .move(edge: .trailing).combined(with: .opacity)
        ))
    }

    // MARK: - All Cleared

    private var allClearedView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(WeepColor.accent)

            Text("All caught up!")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color(.label))

            Text("\(removedIDs.count) item\(removedIDs.count == 1 ? "" : "s") cleared")
                .font(.system(size: 14))
                .foregroundStyle(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
    }

    // MARK: - Helpers

    private func expiryLabel(for item: FoodItem) -> String {
        guard let days = item.daysUntilExpiry else { return "No date" }
        switch days {
        case ..<0: return "Expired \(abs(days))d ago"
        case 0: return "Expires today"
        case 1: return "Expires tomorrow"
        default: return "In \(days) days"
        }
    }

    private func expiryColor(for item: FoodItem) -> Color {
        guard let days = item.daysUntilExpiry else { return Color(.secondaryLabel) }
        if days <= 0 { return WeepColor.alertRed }
        return WeepColor.alertAmber
    }
}
