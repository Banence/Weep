import SwiftUI
import ClerkKit
import Supabase

@Observable
class KitchenStore {
    static let shared = KitchenStore()

    var items: [FoodItem] = []
    var isSyncing: Bool = false

    /// Active items only (not removed)
    var activeItems: [FoodItem] {
        items.filter { $0.isActive }
    }

    /// History: items that have been used, expired, or deleted
    var historyItems: [FoodItem] {
        items.filter { !$0.isActive }.sorted { ($0.removedAt ?? .distantPast) > ($1.removedAt ?? .distantPast) }
    }

    private let storageKey = "weep_kitchen_items"
    private let supabase = SupabaseService.shared.client
    private var realtimeChannel: RealtimeChannelV2?
    /// Track IDs we're currently writing to avoid realtime echo
    private var pendingWriteIDs: Set<UUID> = []

    private init() {
        loadFromLocalCache()
        markExpiredItems()
    }

    // MARK: - Realtime

    func startRealtimeSync() async {
        guard realtimeChannel == nil else { return }

        let channel = supabase.channel("food-items-changes")
        self.realtimeChannel = channel

        nonisolated(unsafe) let store = self
        let _ = channel.onPostgresChange(
            AnyAction.self,
            schema: "public",
            table: "food_items"
        ) { action in
            Task { @MainActor in
                store.handleRealtimeChange(action)
            }
        }

        try? await channel.subscribeWithError()
    }

    func stopRealtimeSync() {
        guard let channel = realtimeChannel else { return }
        self.realtimeChannel = nil
        Task {
            await supabase.removeChannel(channel)
        }
    }

    private func handleRealtimeChange(_ action: AnyAction) {
        switch action {
        case .insert(let insert):
            guard let idString = insert.record["id"]?.value as? String,
                  let id = UUID(uuidString: idString) else { return }
            // Skip our own writes
            guard !pendingWriteIDs.contains(id),
                  !items.contains(where: { $0.id == id }) else { return }
            Task { await syncWithRemote() }

        case .update(let update):
            guard let idString = update.record["id"]?.value as? String,
                  let id = UUID(uuidString: idString) else { return }
            // Skip our own writes
            guard !pendingWriteIDs.contains(id) else { return }
            Task { await syncWithRemote() }

        case .delete(let delete):
            guard let idString = delete.oldRecord["id"]?.value as? String,
                  let id = UUID(uuidString: idString) else { return }
            guard !pendingWriteIDs.contains(id) else { return }
            items.removeAll { $0.id == id }
            saveToLocalCache()
            NotificationManager.rescheduleAll(items: activeItems)
        }
    }

    // MARK: - Auto-Expire

    func markExpiredItems() {
        var changed: [FoodItem] = []
        for i in items.indices {
            guard items[i].isActive,
                  let days = items[i].daysUntilExpiry,
                  days < 0 else { continue }
            items[i].removedAt = Date()
            items[i].removedReason = .expired
            changed.append(items[i])
        }
        guard !changed.isEmpty else { return }
        saveToLocalCache()
        NotificationManager.rescheduleAll(items: activeItems)
        Task {
            for item in changed {
                await remoteUpdateStatus(item)
            }
        }
    }

    // MARK: - Public API

    func addItem(_ item: FoodItem) {
        items.insert(item, at: 0)
        saveToLocalCache()
        NotificationManager.rescheduleAll(items: activeItems)

        Task {
            pendingWriteIDs.insert(item.id)
            await remoteSave(item)
            pendingWriteIDs.remove(item.id)
        }
    }

    func removeItem(_ item: FoodItem, reason: RemovalReason = .used) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].removedAt = Date()
        items[index].removedReason = reason
        let updatedItem = items[index]
        saveToLocalCache()
        NotificationManager.rescheduleAll(items: activeItems)

        Task {
            pendingWriteIDs.insert(updatedItem.id)
            await remoteUpdateStatus(updatedItem)
            pendingWriteIDs.remove(updatedItem.id)
        }
    }

    func updateItem(_ item: FoodItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
        saveToLocalCache()
        NotificationManager.rescheduleAll(items: activeItems)
        // Check if the updated expiry date makes it expired
        markExpiredItems()

        Task {
            pendingWriteIDs.insert(item.id)
            await remoteSave(item)
            pendingWriteIDs.remove(item.id)
        }
    }

    func clearAll() {
        let ids = items.map(\.id)
        items.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
        NotificationManager.rescheduleAll(items: [])

        Task {
            guard let userId = currentUserId else { return }
            for id in ids { pendingWriteIDs.insert(id) }
            _ = try? await supabase
                .from("food_items")
                .delete()
                .eq("user_id", value: userId)
                .execute()
            await SupabaseService.deleteAllProductImages(userId: userId)
            for id in ids { pendingWriteIDs.remove(id) }
        }
    }

    var sortedItems: [FoodItem] {
        activeItems.sorted { a, b in
            guard let daysA = a.daysUntilExpiry else { return false }
            guard let daysB = b.daysUntilExpiry else { return true }
            return daysA < daysB
        }
    }

    /// Fetch items from Supabase and merge with local cache
    func syncWithRemote() async {
        guard let userId = currentUserId else { return }
        isSyncing = true
        defer { isSyncing = false }

        do {
            let dtos: [FoodItemDTO] = try await supabase
                .from("food_items")
                .select()
                .eq("user_id", value: userId)
                .order("date_added", ascending: false)
                .execute()
                .value

            // Download images in parallel
            let imageMap = await withTaskGroup(
                of: (Int, Data?).self,
                returning: [(Int, Data?)].self
            ) { group in
                for (index, dto) in dtos.enumerated() {
                    group.addTask {
                        var data: Data?
                        if let path = dto.productImageUrl, !path.isEmpty {
                            data = await SupabaseService.downloadProductImage(path: path)
                        }
                        return (index, data)
                    }
                }
                var results: [(Int, Data?)] = []
                for await result in group {
                    results.append(result)
                }
                return results
            }

            var imageDataByIndex: [Int: Data?] = [:]
            for (index, data) in imageMap {
                imageDataByIndex[index] = data
            }

            let remoteItems = dtos.enumerated().map { index, dto in
                FoodItem.fromDTO(dto, imageData: imageDataByIndex[index] ?? nil)
            }

            // Merge: keep local items not yet on server
            let remoteIDs = Set(remoteItems.map(\.id))
            let localOnly = self.items.filter { !remoteIDs.contains($0.id) }
            self.items = localOnly + remoteItems
            self.items.sort { $0.dateAdded > $1.dateAdded }
            self.saveToLocalCache()
            NotificationManager.rescheduleAll(items: self.activeItems)
            self.markExpiredItems()
        } catch {
            print("[KitchenStore] Sync failed: \(error)")
        }
    }

    // MARK: - Private Helpers

    private var currentUserId: String? {
        Clerk.shared.user?.id
    }

    /// Full save — uploads image + all fields.
    private func remoteSave(_ item: FoodItem) async {
        guard let userId = currentUserId else { return }

        // Only upload image if we have local image data
        var imagePath: String?
        if let imageData = item.productImageData {
            let compressed = UIImage(data: imageData)?.jpegData(compressionQuality: 0.7) ?? imageData
            imagePath = await SupabaseService.uploadProductImage(
                userId: userId, itemId: item.id, imageData: compressed
            )
        } else {
            // Preserve existing image path — fetch it from DB before overwriting
            if let existing: [FoodItemDTO] = try? await supabase
                .from("food_items")
                .select("product_image_url")
                .eq("id", value: item.id.uuidString)
                .limit(1)
                .execute()
                .value,
               let existingPath = existing.first?.productImageUrl {
                imagePath = existingPath
            }
        }

        let dto = item.toDTO(userId: userId, imagePath: imagePath)
        do {
            try await supabase
                .from("food_items")
                .upsert(dto, onConflict: "id")
                .execute()
        } catch {
            print("[KitchenStore] Remote save failed: \(error)")
        }
    }

    /// Partial update — only updates removed_at and removed_reason.
    private func remoteUpdateStatus(_ item: FoodItem) async {
        guard let userId = currentUserId else { return }

        struct StatusUpdate: Codable {
            let removedAt: Date?
            let removedReason: String?
            enum CodingKeys: String, CodingKey {
                case removedAt = "removed_at"
                case removedReason = "removed_reason"
            }
        }

        let update = StatusUpdate(
            removedAt: item.removedAt,
            removedReason: item.removedReason?.rawValue
        )

        do {
            try await supabase
                .from("food_items")
                .update(update)
                .eq("id", value: item.id.uuidString)
                .eq("user_id", value: userId)
                .execute()
        } catch {
            print("[KitchenStore] Remote status update failed: \(error)")
        }
    }

    // MARK: - Local Cache

    private func saveToLocalCache() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadFromLocalCache() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([FoodItem].self, from: data) else { return }
        items = decoded
    }
}
