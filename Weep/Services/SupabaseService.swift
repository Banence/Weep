import Foundation
import Supabase
import ClerkKit

struct SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        let supabaseURL = URL(string: "https://timkfljiznllstxoknvc.supabase.co")!
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRpbWtmbGppem5sbHN0eG9rbnZjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2MjE2OTQsImV4cCI6MjA5MDE5NzY5NH0.I4C7rCCuCSqTOvf77Vk01-9DVbbLQVJAW8x-XuviOjw"

        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    accessToken: {
                        try await Clerk.shared.session?.getToken()
                    }
                )
            )
        )
    }

    // MARK: - Storage (Product Images)

    private static let imageBucket = "product-images"

    /// Upload product image to Supabase Storage. Returns the storage path.
    static func uploadProductImage(userId: String, itemId: UUID, imageData: Data) async -> String? {
        let path = "\(userId)/\(itemId.uuidString).jpg"
        do {
            try await shared.client.storage
                .from(imageBucket)
                .upload(path, data: imageData, options: .init(contentType: "image/jpeg", upsert: true))
            return path
        } catch {
            print("[SupabaseStorage] Upload failed: \(error)")
            return nil
        }
    }

    /// Download product image from Supabase Storage.
    static func downloadProductImage(path: String) async -> Data? {
        do {
            return try await shared.client.storage
                .from(imageBucket)
                .download(path: path)
        } catch {
            print("[SupabaseStorage] Download failed: \(error)")
            return nil
        }
    }

    /// Delete product image from Supabase Storage.
    static func deleteProductImage(path: String) async {
        do {
            try await shared.client.storage
                .from(imageBucket)
                .remove(paths: [path])
        } catch {
            print("[SupabaseStorage] Delete failed: \(error)")
        }
    }

    /// Delete all images for a user.
    static func deleteAllProductImages(userId: String) async {
        do {
            let files = try await shared.client.storage
                .from(imageBucket)
                .list(path: userId)
            let paths = files.map { "\(userId)/\($0.name)" }
            if !paths.isEmpty {
                try await shared.client.storage
                    .from(imageBucket)
                    .remove(paths: paths)
            }
        } catch {
            print("[SupabaseStorage] Delete all failed: \(error)")
        }
    }
}

// MARK: - Database DTOs

struct ProfileDTO: Codable {
    let id: UUID?
    let userId: String
    let displayName: String
    let avatarChoice: String
    let householdAdults: Int
    let householdChildren: Int
    let hasPets: Bool
    let shoppingFrequency: String?
    let shoppingLocations: [String]
    let storageZones: [StorageZoneDTO]
    let dietaryPreferences: [String]
    let selfReportedWasteLevel: Double
    let primaryGoal: String?
    let onboardingCompleted: Bool
    let appTheme: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case displayName = "display_name"
        case avatarChoice = "avatar_choice"
        case householdAdults = "household_adults"
        case householdChildren = "household_children"
        case hasPets = "has_pets"
        case shoppingFrequency = "shopping_frequency"
        case shoppingLocations = "shopping_locations"
        case storageZones = "storage_zones"
        case dietaryPreferences = "dietary_preferences"
        case selfReportedWasteLevel = "self_reported_waste_level"
        case primaryGoal = "primary_goal"
        case onboardingCompleted = "onboarding_completed"
        case appTheme = "app_theme"
    }
}

struct StorageZoneDTO: Codable {
    let id: String
    let name: String
    let icon: String
    let isEnabled: Bool
}

struct FoodItemDTO: Codable {
    let id: UUID
    let userId: String
    let name: String
    let expiryDate: Date?
    let productImageUrl: String?
    let storageZone: String
    let dateAdded: Date
    let brand: String?
    let category: String?
    let productDescription: String?
    let ingredients: [String]?
    let allergens: [String]?
    let storageTips: String?
    let servingSize: String?
    let weight: String?
    let nutrition: NutritionInfo?
    let removedAt: Date?
    let removedReason: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case expiryDate = "expiry_date"
        case productImageUrl = "product_image_url"
        case storageZone = "storage_zone"
        case dateAdded = "date_added"
        case brand, category
        case productDescription = "product_description"
        case ingredients, allergens
        case storageTips = "storage_tips"
        case servingSize = "serving_size"
        case weight, nutrition
        case removedAt = "removed_at"
        case removedReason = "removed_reason"
    }
}

// MARK: - Conversion Helpers

extension FoodItem {
    /// Convert to DTO for Supabase. Image is uploaded separately; pass the storage path.
    func toDTO(userId: String, imagePath: String? = nil) -> FoodItemDTO {
        FoodItemDTO(
            id: id,
            userId: userId,
            name: name,
            expiryDate: expiryDate,
            productImageUrl: imagePath,
            storageZone: storageZone,
            dateAdded: dateAdded,
            brand: brand,
            category: category,
            productDescription: productDescription,
            ingredients: ingredients,
            allergens: allergens,
            storageTips: storageTips,
            servingSize: servingSize,
            weight: weight,
            nutrition: nutrition,
            removedAt: removedAt,
            removedReason: removedReason?.rawValue
        )
    }

    /// Convert from DTO. Image data must be downloaded separately.
    static func fromDTO(_ dto: FoodItemDTO, imageData: Data? = nil) -> FoodItem {
        FoodItem(
            id: dto.id,
            name: dto.name,
            expiryDate: dto.expiryDate,
            productImageData: imageData,
            storageZone: dto.storageZone,
            dateAdded: dto.dateAdded,
            brand: dto.brand,
            category: dto.category,
            productDescription: dto.productDescription,
            ingredients: dto.ingredients,
            allergens: dto.allergens,
            storageTips: dto.storageTips,
            servingSize: dto.servingSize,
            weight: dto.weight,
            nutrition: dto.nutrition,
            removedAt: dto.removedAt,
            removedReason: RemovalReason(rawValue: dto.removedReason ?? "")
        )
    }
}
