import SwiftUI

enum HistoryFilter: String, CaseIterable {
    case all = "All"
    case used = "Used"
    case expired = "Expired"
    case deleted = "Deleted"

    var reason: RemovalReason? {
        switch self {
        case .all: return nil
        case .used: return .used
        case .expired: return .expired
        case .deleted: return .deleted
        }
    }
}

struct HistoryView: View {
    @State private var store = KitchenStore.shared
    @State private var selectedFilter: HistoryFilter = .all
    @State private var selectedItem: FoodItem?

    private var filteredItems: [FoodItem] {
        if let reason = selectedFilter.reason {
            return store.historyItems.filter { $0.removedReason == reason }
        }
        return store.historyItems
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter tabs
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(HistoryFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                if filteredItems.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredItems) { item in
                                Button { selectedItem = item } label: {
                                    historyRow(item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("History")
        }
        .sheet(item: $selectedItem) { item in
            ProductDetailSheet(item: item)
        }
    }

    // MARK: - History Row

    private func historyRow(_ item: FoodItem) -> some View {
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
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(.label))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let reason = item.removedReason {
                        HStack(spacing: 3) {
                            Image(systemName: reason.icon)
                                .font(.system(size: 10))
                            Text(reason.label)
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(reasonColor(reason))
                    }

                    if let date = item.removedAt {
                        Text(date, format: .dateTime.day().month(.abbreviated))
                            .font(.system(size: 12))
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                }
            }

            Spacer(minLength: 0)

            if let brand = item.brand {
                Text(brand)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(.tertiaryLabel))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundColor(Color(.tertiaryLabel))

            Text("No history yet")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(.label))

            Text("Items you use, expire, or delete\nwill appear here")
                .font(.system(size: 15))
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Helpers

    private func reasonColor(_ reason: RemovalReason) -> Color {
        switch reason {
        case .used: return WeepColor.accent
        case .expired: return WeepColor.alertRed
        case .deleted: return Color(.secondaryLabel)
        }
    }
}
