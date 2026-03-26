import Vision
import UIKit

struct ProductIdentifier {

    /// Uses Vision's image classification + text recognition to identify a product.
    /// Returns the best guess product name.
    static func identify(from image: UIImage) async -> String {
        async let classificationResult = classifyImage(image)
        async let textResult = readText(from: image)

        let labels = await classificationResult
        let texts = await textResult

        // Strategy: If we find readable product text on the label, prefer that.
        // Otherwise fall back to Vision classification labels.
        let productText = extractProductName(from: texts)
        if let productText, !productText.isEmpty {
            return productText
        }

        // Use classification labels — filter to food-related ones
        let foodLabels = labels.filter { isFoodRelated($0.key) }
        if let best = foodLabels.max(by: { $0.value < $1.value }), best.value > 0.1 {
            return best.key.capitalized
        }

        // Fall back to top classification
        if let top = labels.max(by: { $0.value < $1.value }) {
            return top.key.capitalized
        }

        return ""
    }

    // MARK: - Classification

    private static func classifyImage(_ image: UIImage) async -> [String: Float] {
        guard let cgImage = image.cgImage else { return [:] }

        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage)

        do {
            try handler.perform([request])
        } catch {
            return [:]
        }

        guard let results = request.results else { return [:] }

        var labels: [String: Float] = [:]
        for observation in results where observation.confidence > 0.05 {
            labels[observation.identifier] = observation.confidence
        }
        return labels
    }

    // MARK: - Text Recognition

    private static func readText(from image: UIImage) async -> [String] {
        guard let cgImage = image.cgImage else { return [] }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage)

        do {
            try handler.perform([request])
        } catch {
            return []
        }

        guard let observations = request.results else { return [] }

        return observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }
    }

    // MARK: - Helpers

    private static func extractProductName(from texts: [String]) -> String? {
        // Look for product-name-like text: longer strings, not just numbers/dates
        let candidates = texts.filter { text in
            let trimmed = text.trimmingCharacters(in: .whitespaces)
            guard trimmed.count >= 3 else { return false }

            // Skip lines that are purely numeric or date-like
            let numericChars = trimmed.filter { $0.isNumber || $0 == "/" || $0 == "-" || $0 == "." }
            if numericChars.count > trimmed.count / 2 { return false }

            // Skip very common non-product label text
            let lower = trimmed.lowercased()
            let skipWords = ["best before", "use by", "exp", "lot", "batch", "net wt", "ingredients", "nutrition", "calories", "storage", "keep refrigerated", "www", "http", ".com"]
            for skip in skipWords {
                if lower.contains(skip) { return false }
            }

            return true
        }

        // Return the first reasonable candidate (usually the brand/product name is prominent)
        return candidates.first
    }

    private static let foodKeywords: Set<String> = [
        "food", "fruit", "vegetable", "meat", "bread", "dairy", "cheese", "milk",
        "egg", "fish", "seafood", "poultry", "beverage", "drink", "juice", "water",
        "snack", "candy", "chocolate", "cereal", "grain", "rice", "pasta", "noodle",
        "soup", "sauce", "condiment", "spice", "herb", "nut", "seed", "bean",
        "yogurt", "butter", "cream", "ice_cream", "cake", "pie", "cookie",
        "apple", "banana", "orange", "grape", "strawberry", "blueberry", "lemon",
        "tomato", "potato", "carrot", "onion", "pepper", "lettuce", "broccoli",
        "chicken", "beef", "pork", "lamb", "turkey", "ham", "bacon", "sausage",
        "pizza", "sandwich", "burger", "taco", "salad", "wrap",
    ]

    private static func isFoodRelated(_ label: String) -> Bool {
        let lower = label.lowercased().replacingOccurrences(of: "_", with: " ")
        for keyword in foodKeywords {
            if lower.contains(keyword.replacingOccurrences(of: "_", with: " ")) {
                return true
            }
        }
        return false
    }
}
