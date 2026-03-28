import Foundation

struct MealSuggestion: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    let name: String
    let description: String
    let ingredients: [String]
    let steps: [String]
    let cookingTime: String
    let servings: String
    let difficulty: String

    enum CodingKeys: String, CodingKey {
        case name, description, ingredients, steps
        case cookingTime = "cooking_time"
        case servings, difficulty
    }

    init(id: UUID = UUID(), name: String, description: String, ingredients: [String], steps: [String] = [], cookingTime: String, servings: String = "2", difficulty: String) {
        self.id = id
        self.name = name
        self.description = description
        self.ingredients = ingredients
        self.steps = steps
        self.cookingTime = cookingTime
        self.servings = servings
        self.difficulty = difficulty
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        self.ingredients = try container.decode([String].self, forKey: .ingredients)
        self.steps = (try? container.decode([String].self, forKey: .steps)) ?? []
        self.cookingTime = try container.decode(String.self, forKey: .cookingTime)
        self.servings = (try? container.decode(String.self, forKey: .servings)) ?? "2"
        self.difficulty = try container.decode(String.self, forKey: .difficulty)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(ingredients, forKey: .ingredients)
        try container.encode(steps, forKey: .steps)
        try container.encode(cookingTime, forKey: .cookingTime)
        try container.encode(servings, forKey: .servings)
        try container.encode(difficulty, forKey: .difficulty)
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: MealSuggestion, rhs: MealSuggestion) -> Bool { lhs.id == rhs.id }
}

struct MealPlan: Codable, Identifiable {
    let id: UUID
    let title: String
    let meals: [MealSuggestion]
    let usedItemIds: [UUID]
    let createdAt: Date

    init(id: UUID = UUID(), title: String, meals: [MealSuggestion], usedItemIds: [UUID], createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.meals = meals
        self.usedItemIds = usedItemIds
        self.createdAt = createdAt
    }
}

struct MealPlanDTO: Codable {
    let id: UUID?
    let userId: String
    let title: String
    let meals: [MealSuggestion]
    let usedItemIds: [UUID]
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title, meals
        case usedItemIds = "used_item_ids"
        case createdAt = "created_at"
    }
}

enum MealPlanError: Error {
    case noApiKey
    case noItems
    case networkError(String)
    case apiError(Int, String)
    case parseError

    var message: String {
        switch self {
        case .noApiKey: return "API key not configured"
        case .noItems: return "No items in your kitchen"
        case .networkError(let msg): return "Network error: \(msg)"
        case .apiError(let code, let body): return "API error (\(code)): \(body.prefix(100))"
        case .parseError: return "Couldn't parse the AI response"
        }
    }
}

struct MealPlanGenerator {

    private static var apiKey: String {
        if let key = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String,
           !key.isEmpty, key.hasPrefix("sk-") {
            return key
        }
        if let key = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"],
           !key.isEmpty, key.hasPrefix("sk-") {
            return key
        }
        return ""
    }

    private static let endpoint = "https://api.anthropic.com/v1/messages"
    private static let model = "claude-sonnet-4-5-20250929"

    static func generateMealPlan(from items: [FoodItem]) async -> Result<[MealSuggestion], MealPlanError> {
        guard !apiKey.isEmpty else { return .failure(.noApiKey) }

        let prioritized = items
            .filter { $0.isActive }
            .sorted { ($0.daysUntilExpiry ?? 999) < ($1.daysUntilExpiry ?? 999) }
            .prefix(15)

        guard !prioritized.isEmpty else { return .failure(.noItems) }

        let itemList = prioritized.map { item in
            var desc = "- \(item.name)"
            if let days = item.daysUntilExpiry {
                if days == 0 { desc += " (expires TODAY)" }
                else if days == 1 { desc += " (expires TOMORROW)" }
                else if days <= 3 { desc += " (expires in \(days) days — USE SOON)" }
                else { desc += " (\(days) days left)" }
            }
            return desc
        }.joined(separator: "\n")

        let prompt = """
        You are a meal planning assistant for a food waste app. The user has these items sorted by expiry urgency:

        \(itemList)

        Suggest 3 simple, practical meals using these items. Prioritize items expiring soonest.

        Return ONLY a JSON array with exactly 3 objects. Each object must have these fields:
        {
          "name": "Meal name",
          "description": "One appetizing sentence describing the dish",
          "ingredients": ["item1 from the list", "item2 from the list"],
          "steps": ["Step 1: Do this", "Step 2: Do that", "Step 3: Finish"],
          "cooking_time": "15 min",
          "servings": "2",
          "difficulty": "Easy"
        }

        Rules:
        - "ingredients" must only contain items from the user's list above
        - "steps" should be 3-6 clear, concise cooking instructions
        - "difficulty" must be "Easy", "Medium", or "Hard"
        - You may assume basic pantry staples (salt, pepper, oil, garlic, butter) are available
        - Keep meals simple and practical
        - Return ONLY valid JSON array, no markdown fences, no extra text
        """

        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 2048,
            "messages": [["role": "user", "content": prompt]]
        ]

        guard let url = URL(string: endpoint),
              let bodyData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            return .failure(.parseError)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = bodyData
        request.timeoutInterval = 30

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.networkError("Invalid response"))
            }

            guard httpResponse.statusCode == 200 else {
                let body = String(data: data, encoding: .utf8) ?? ""
                return .failure(.apiError(httpResponse.statusCode, body))
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let content = json["content"] as? [[String: Any]],
                  let textBlock = content.first(where: { $0["type"] as? String == "text" }),
                  let text = textBlock["text"] as? String else {
                return .failure(.parseError)
            }

            let cleaned = extractJSON(from: text)
            guard let jsonData = cleaned.data(using: .utf8),
                  let meals = try? JSONDecoder().decode([MealSuggestion].self, from: jsonData),
                  !meals.isEmpty else {
                return .failure(.parseError)
            }

            return .success(meals)
        } catch {
            return .failure(.networkError(error.localizedDescription))
        }
    }

    private static func extractJSON(from text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") { cleaned = String(cleaned.dropFirst(7)) }
        else if cleaned.hasPrefix("```") { cleaned = String(cleaned.dropFirst(3)) }
        if cleaned.hasSuffix("```") { cleaned = String(cleaned.dropLast(3)) }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
