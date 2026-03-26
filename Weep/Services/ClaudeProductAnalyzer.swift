import UIKit

struct ProductAnalysisResult: Codable {
    var name: String
    var brand: String?
    var category: String?
    var description: String?
    var ingredients: [String]?
    var allergens: [String]?
    var storageTips: String?
    var servingSize: String?
    var weight: String?
    var suggestedStorageZone: String?
    var nutrition: NutritionAnalysis?

    struct NutritionAnalysis: Codable {
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
    }
}

struct ClaudeProductAnalyzer {

    // NOTE: For production, store this securely (Keychain, backend proxy, etc.)
    // This is a development key for prototyping only.
    private static let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? ""
    private static let endpoint = "https://api.anthropic.com/v1/messages"
    private static let model = "claude-haiku-4-5-20251001"

    static func analyze(image: UIImage) async -> ProductAnalysisResult? {
        guard let imageData = image.jpegData(compressionQuality: 0.6) else { return nil }
        let base64Image = imageData.base64EncodedString()

        let prompt = """
        Analyze this food/grocery product image. Return a JSON object with ALL of the following fields. \
        For any field you cannot determine from the image, use null. Be as detailed as possible.

        {
          "name": "Product name (e.g. 'Greek Yogurt', 'Organic Whole Milk')",
          "brand": "Brand name if visible",
          "category": "Category (e.g. 'Dairy', 'Produce', 'Bakery', 'Meat', 'Beverage', 'Snack', 'Condiment', 'Frozen', 'Canned', 'Grain')",
          "description": "Brief product description (1-2 sentences)",
          "ingredients": ["ingredient1", "ingredient2"],
          "allergens": ["allergen1", "allergen2"],
          "storageTips": "How to best store this product for maximum freshness",
          "servingSize": "Serving size if visible (e.g. '1 cup (240ml)')",
          "weight": "Net weight if visible (e.g. '500g', '16 oz')",
          "suggestedStorageZone": "Fridge, Freezer, or Pantry",
          "nutrition": {
            "calories": "amount per serving (e.g. '150 kcal')",
            "totalFat": "amount (e.g. '8g')",
            "saturatedFat": "amount",
            "transFat": "amount",
            "cholesterol": "amount",
            "sodium": "amount",
            "totalCarbohydrates": "amount",
            "dietaryFiber": "amount",
            "totalSugars": "amount",
            "protein": "amount",
            "vitaminA": "amount or percentage",
            "vitaminC": "amount or percentage",
            "vitaminD": "amount or percentage",
            "calcium": "amount or percentage",
            "iron": "amount or percentage",
            "potassium": "amount or percentage"
          }
        }

        If this is a fresh produce item (fruit, vegetable, etc.) without packaging, still provide \
        typical nutritional information, common allergens, and storage tips based on your knowledge.

        Return ONLY the JSON object, no other text.
        """

        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64Image,
                            ],
                        ],
                        [
                            "type": "text",
                            "text": prompt,
                        ],
                    ],
                ]
            ],
        ]

        guard let url = URL(string: endpoint),
              let bodyData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            return nil
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

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            // Parse the Claude response
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let content = json["content"] as? [[String: Any]],
                  let textBlock = content.first(where: { $0["type"] as? String == "text" }),
                  let text = textBlock["text"] as? String else {
                return nil
            }

            // Extract JSON from the response (Claude might wrap it in markdown code blocks)
            let cleanedJSON = extractJSON(from: text)
            guard let jsonData = cleanedJSON.data(using: .utf8) else { return nil }

            let decoder = JSONDecoder()
            return try? decoder.decode(ProductAnalysisResult.self, from: jsonData)
        } catch {
            return nil
        }
    }

    private static func extractJSON(from text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove markdown code fences if present
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Convert analysis result into FoodItem fields
    static func applyAnalysis(_ result: ProductAnalysisResult, to item: inout FoodItem) {
        item.name = result.name
        item.brand = result.brand
        item.category = result.category
        item.productDescription = result.description
        item.ingredients = result.ingredients
        item.allergens = result.allergens
        item.storageTips = result.storageTips
        item.servingSize = result.servingSize
        item.weight = result.weight

        if let zone = result.suggestedStorageZone {
            item.storageZone = zone
        }

        if let n = result.nutrition {
            item.nutrition = NutritionInfo(
                calories: n.calories,
                totalFat: n.totalFat,
                saturatedFat: n.saturatedFat,
                transFat: n.transFat,
                cholesterol: n.cholesterol,
                sodium: n.sodium,
                totalCarbohydrates: n.totalCarbohydrates,
                dietaryFiber: n.dietaryFiber,
                totalSugars: n.totalSugars,
                protein: n.protein,
                vitaminA: n.vitaminA,
                vitaminC: n.vitaminC,
                vitaminD: n.vitaminD,
                calcium: n.calcium,
                iron: n.iron,
                potassium: n.potassium
            )
        }
    }
}
