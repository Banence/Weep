import Vision
import UIKit

struct ExpiryDateParser {

    /// Extract date from an image using OCR
    static func extractDate(from image: UIImage) async -> Date? {
        guard let cgImage = image.cgImage else { return nil }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage)

        do {
            try handler.perform([request])
        } catch {
            return nil
        }

        guard let observations = request.results else { return nil }

        let recognizedStrings = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }

        // Try each line individually first, then try combined text
        for line in recognizedStrings {
            if let date = parseDate(from: line) {
                return date
            }
        }

        let allText = recognizedStrings.joined(separator: " ")
        return parseDate(from: allText)
    }

    /// Parse a date from arbitrary text — used by both OCR and live scanner
    static func parseDate(from text: String) -> Date? {
        let cleaned = text
            .replacingOccurrences(of: "O", with: "0", options: .literal) // Common OCR misread
            .replacingOccurrences(of: "l", with: "1", options: .literal) // Common OCR misread
            .trimmingCharacters(in: .whitespaces)

        // First try Apple's built-in data detector for dates
        if let date = detectDateWithNSDataDetector(cleaned) {
            return date
        }

        // Fall back to manual regex patterns
        return parseWithRegex(cleaned)
    }

    // MARK: - NSDataDetector (Apple's built-in date parser)

    private static func detectDateWithNSDataDetector(_ text: String) -> Date? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        let matches = detector.matches(in: text, range: range)

        for match in matches {
            if let date = match.date {
                // Only accept future dates or dates within last 30 days (for recently expired items)
                let daysFromNow = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
                if daysFromNow >= -30 {
                    return date
                }
            }
        }

        return nil
    }

    // MARK: - Regex Fallback

    private static func parseWithRegex(_ text: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        // Pattern → format pairs
        let patternFormats: [(pattern: String, formats: [String])] = [
            // DD/MM/YYYY variants
            (#"(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})"#, [
                "dd/MM/yyyy", "dd-MM-yyyy", "dd.MM.yyyy",
                "MM/dd/yyyy", "MM-dd-yyyy", "MM.dd.yyyy",
            ]),
            // YYYY/MM/DD variants
            (#"(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})"#, [
                "yyyy/MM/dd", "yyyy-MM-dd", "yyyy.MM.dd",
            ]),
            // DD/MM/YY variants
            (#"(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2})\b"#, [
                "dd/MM/yy", "dd-MM-yy", "dd.MM.yy",
                "MM/dd/yy", "MM-dd-yy", "MM.dd.yy",
            ]),
            // Month DD, YYYY
            (#"([A-Za-z]{3,9})\s+(\d{1,2}),?\s+(\d{4})"#, [
                "MMM dd, yyyy", "MMM dd yyyy", "MMMM dd, yyyy", "MMMM dd yyyy",
            ]),
            // DD Month YYYY
            (#"(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{4})"#, [
                "dd MMM yyyy", "dd MMMM yyyy",
            ]),
            // DD Month YY
            (#"(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{2})\b"#, [
                "dd MMM yy", "dd MMMM yy",
            ]),
            // MM/YYYY (no day, common on products)
            (#"\b(\d{1,2})[/\-.](\d{4})\b"#, [
                "MM/yyyy", "MM-yyyy", "MM.yyyy",
            ]),
            // MM/YY (no day, very common on products)
            (#"\b(\d{1,2})[/\-.](\d{2})\b"#, [
                "MM/yy", "MM-yy",
            ]),
        ]

        for (pattern, formats) in patternFormats {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                  let range = Range(match.range, in: text) else {
                continue
            }

            let matchString = String(text[range])

            for format in formats {
                dateFormatter.dateFormat = format
                guard var date = dateFormatter.date(from: matchString) else { continue }

                // For month/year-only formats, use last day of month
                if !format.contains("dd") {
                    let calendar = Calendar.current
                    var components = calendar.dateComponents([.year, .month], from: date)
                    if let year = components.year, year < 100 {
                        components.year = 2000 + year
                    }
                    if let monthDate = calendar.date(from: components),
                       let dayRange = calendar.range(of: .day, in: .month, for: monthDate) {
                        components.day = dayRange.upperBound - 1
                        date = calendar.date(from: components) ?? date
                    }
                }

                // Sanity check: date should be within a reasonable range
                let yearsFromNow = Calendar.current.dateComponents([.year], from: Date(), to: date).year ?? 0
                if yearsFromNow >= -1 && yearsFromNow <= 10 {
                    return date
                }
            }
        }

        return nil
    }
}
