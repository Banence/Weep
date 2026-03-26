import SwiftUI

@Observable
class KitchenStore {
    static let shared = KitchenStore()

    var items: [FoodItem] = []

    private let storageKey = "weep_kitchen_items"

    private init() {
        load()
    }

    func addItem(_ item: FoodItem) {
        items.insert(item, at: 0)
        save()
    }

    func removeItem(_ item: FoodItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func updateItem(_ item: FoodItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
        save()
    }

    var sortedItems: [FoodItem] {
        items.sorted { a, b in
            guard let daysA = a.daysUntilExpiry else { return false }
            guard let daysB = b.daysUntilExpiry else { return true }
            return daysA < daysB
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([FoodItem].self, from: data) else { return }
        items = decoded
    }
}
