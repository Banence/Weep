import SwiftUI
import VisionKit

struct DateScannerView: UIViewControllerRepresentable {
    @Binding var scannedDate: Date?
    @Binding var scannedText: String
    let onDateFound: () -> Void

    static var isDeviceSupported: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator

        // Start scanning after a brief delay to allow the view to layout
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            try? scanner.startScanning()
        }

        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: DateScannerView
        private var hasFoundDate = false

        init(_ parent: DateScannerView) {
            self.parent = parent
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            processItem(item)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            processItems(allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            processItems(allItems)
        }

        func dataScannerDidBecomeUnavailable(_ dataScanner: DataScannerViewController) {}

        private func processItem(_ item: RecognizedItem) {
            guard case .text(let text) = item else { return }
            let recognized = text.transcript
            checkForDate(in: recognized)
        }

        private func processItems(_ items: [RecognizedItem]) {
            // Combine all visible text and check for dates
            var allTexts: [String] = []
            for item in items {
                guard case .text(let text) = item else { continue }
                allTexts.append(text.transcript)
            }

            // Show what's being scanned
            let combined = allTexts.joined(separator: " | ")
            Task { @MainActor in
                self.parent.scannedText = allTexts.last ?? ""
            }

            // Check each text block for dates
            for text in allTexts {
                checkForDate(in: text)
            }

            // Also try combined text
            checkForDate(in: allTexts.joined(separator: " "))
        }

        private func checkForDate(in text: String) {
            guard !hasFoundDate else { return }

            if let date = ExpiryDateParser.parseDate(from: text) {
                hasFoundDate = true
                Task { @MainActor in
                    self.parent.scannedDate = date
                    self.parent.scannedText = text
                    WeepHaptics.success()
                    self.parent.onDateFound()
                }
            }
        }
    }
}
