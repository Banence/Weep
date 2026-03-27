import Foundation

enum RemovalReason: String, Codable, CaseIterable {
    case used
    case expired
    case deleted

    var label: String {
        switch self {
        case .used: return "Used"
        case .expired: return "Expired"
        case .deleted: return "Deleted"
        }
    }

    var icon: String {
        switch self {
        case .used: return "checkmark.circle.fill"
        case .expired: return "xmark.circle.fill"
        case .deleted: return "trash.fill"
        }
    }
}

struct FoodItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var expiryDate: Date?
    var productImageData: Data?
    var storageZone: String
    var dateAdded: Date

    // Rich data from AI analysis
    var brand: String?
    var category: String?
    var productDescription: String?
    var ingredients: [String]?
    var allergens: [String]?
    var storageTips: String?
    var servingSize: String?
    var weight: String?

    // Nutrition per serving
    var nutrition: NutritionInfo?

    // History tracking
    var removedAt: Date?
    var removedReason: RemovalReason?

    var isActive: Bool { removedAt == nil }

    init(
        id: UUID = UUID(),
        name: String,
        expiryDate: Date? = nil,
        productImageData: Data? = nil,
        storageZone: String = "Fridge",
        dateAdded: Date = Date(),
        brand: String? = nil,
        category: String? = nil,
        productDescription: String? = nil,
        ingredients: [String]? = nil,
        allergens: [String]? = nil,
        storageTips: String? = nil,
        servingSize: String? = nil,
        weight: String? = nil,
        nutrition: NutritionInfo? = nil,
        removedAt: Date? = nil,
        removedReason: RemovalReason? = nil
    ) {
        self.id = id
        self.name = name
        self.expiryDate = expiryDate
        self.productImageData = productImageData
        self.storageZone = storageZone
        self.dateAdded = dateAdded
        self.brand = brand
        self.category = category
        self.productDescription = productDescription
        self.ingredients = ingredients
        self.allergens = allergens
        self.storageTips = storageTips
        self.servingSize = servingSize
        self.weight = weight
        self.nutrition = nutrition
        self.removedAt = removedAt
        self.removedReason = removedReason
    }

    var daysUntilExpiry: Int? {
        guard let expiryDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: expiryDate)).day
    }

    var freshnessStatus: FreshnessStatus {
        guard let days = daysUntilExpiry else { return .unknown }
        if days < 0 { return .expired }
        if days <= 2 { return .expiringSoon }
        if days <= 5 { return .fresh }
        return .veryFresh
    }

    var hasDetailData: Bool {
        brand != nil || category != nil || productDescription != nil ||
        ingredients != nil || allergens != nil || nutrition != nil
    }
}

struct NutritionInfo: Codable, Equatable {
    var calories: String?
    var totalFat: String?
    var saturatedFat: String?
    var transFat: String?
    var cholesterol: String?
    var sodium: String?
    var totalCarbohydrates: String?
    var dietaryFiber: String?
    var totalSugars: String?
    var protein: String?
    var vitaminA: String?
    var vitaminC: String?
    var vitaminD: String?
    var calcium: String?
    var iron: String?
    var potassium: String?

    var hasAnyData: Bool {
        [calories, totalFat, saturatedFat, transFat, cholesterol, sodium,
         totalCarbohydrates, dietaryFiber, totalSugars, protein,
         vitaminA, vitaminC, vitaminD, calcium, iron, potassium]
            .contains { $0 != nil }
    }
}

enum FreshnessStatus {
    case veryFresh, fresh, expiringSoon, expired, unknown

    var label: String {
        switch self {
        case .veryFresh: return "Fresh"
        case .fresh: return "Good"
        case .expiringSoon: return "Use soon"
        case .expired: return "Expired"
        case .unknown: return "No date"
        }
    }

    var icon: String {
        switch self {
        case .veryFresh: return "leaf.fill"
        case .fresh: return "checkmark.circle.fill"
        case .expiringSoon: return "exclamationmark.triangle.fill"
        case .expired: return "xmark.circle.fill"
        case .unknown: return "questionmark.circle"
        }
    }
}
