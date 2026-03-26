import Foundation

enum ShoppingFrequency: String, CaseIterable, Codable {
    case daily = "Daily"
    case twoThreeTimesWeek = "2–3 times a week"
    case weekly = "Once a week"
    case biweekly = "Every 2 weeks or less"

    var icon: String {
        switch self {
        case .daily: return "cart"
        case .twoThreeTimesWeek: return "cart.fill"
        case .weekly: return "basket"
        case .biweekly: return "shippingbox"
        }
    }

    var description: String {
        switch self {
        case .daily: return "Small, frequent trips"
        case .twoThreeTimesWeek: return "A few trips a week"
        case .weekly: return "The big weekly shop"
        case .biweekly: return "Bulk buying"
        }
    }
}

enum ShoppingLocation: String, CaseIterable, Codable {
    case supermarket = "Supermarket"
    case farmersMarket = "Farmers market"
    case onlineDelivery = "Online delivery"
    case specialty = "Specialty / Organic"
    case wholesale = "Wholesale / Bulk"

    var icon: String {
        switch self {
        case .supermarket: return "building.2"
        case .farmersMarket: return "leaf"
        case .onlineDelivery: return "box.truck"
        case .specialty: return "storefront"
        case .wholesale: return "shippingbox.fill"
        }
    }
}

struct StorageZone: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var icon: String
    var isEnabled: Bool

    static let defaults: [StorageZone] = [
        StorageZone(id: UUID(), name: "Fridge", icon: "refrigerator", isEnabled: true),
        StorageZone(id: UUID(), name: "Freezer", icon: "snowflake", isEnabled: true),
        StorageZone(id: UUID(), name: "Pantry", icon: "cabinet", isEnabled: true),
    ]
}

enum DietaryPreference: String, CaseIterable, Codable {
    case none = "No restrictions"
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case pescatarian = "Pescatarian"
    case glutenFree = "Gluten-free"
    case dairyFree = "Dairy-free"
    case nutAllergy = "Nut allergy"
    case halal = "Halal"
    case kosher = "Kosher"
    case lowFodmap = "Low FODMAP"

    var icon: String {
        switch self {
        case .none: return "fork.knife"
        case .vegetarian: return "leaf.fill"
        case .vegan: return "leaf.arrow.circlepath"
        case .pescatarian: return "fish"
        case .glutenFree: return "xmark.circle"
        case .dairyFree: return "drop.triangle"
        case .nutAllergy: return "exclamationmark.triangle"
        case .halal: return "moon.stars.fill"
        case .kosher: return "staroflife"
        case .lowFodmap: return "flask.fill"
        }
    }
}

enum PrimaryGoal: String, CaseIterable, Codable {
    case wasteLess = "Waste Less"
    case saveMoney = "Save Money"
    case helpPlanet = "Help the Planet"

    var icon: String {
        switch self {
        case .wasteLess: return "leaf.fill"
        case .saveMoney: return "eurosign.circle.fill"
        case .helpPlanet: return "globe.europe.africa.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .wasteLess: return "Reduce how much food you throw away"
        case .saveMoney: return "Stop wasting money on food you don't eat"
        case .helpPlanet: return "Reduce your environmental footprint"
        }
    }

    var color: String {
        switch self {
        case .wasteLess: return "primaryGreen"
        case .saveMoney: return "accentWarm"
        case .helpPlanet: return "alertAmber"
        }
    }
}

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case aboutYou
    case greeting
    case household
    case shoppingFrequency
    case shoppingLocations
    case kitchenZones
    case dietary
    case wasteReality
    case goal
    case permissions
    case firstScan

    var canSkip: Bool {
        switch self {
        case .welcome, .greeting, .permissions, .firstScan: return false
        default: return true
        }
    }
}
