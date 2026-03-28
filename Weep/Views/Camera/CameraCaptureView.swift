import SwiftUI
import PhotosUI
import VisionKit

enum CaptureStep {
    case product
    case expiryDate
    case reviewing
}

struct CameraCaptureView: View {
    @State private var cameraService = CameraService()
    @State private var captureStep: CaptureStep = .product
    @State private var productImage: UIImage?
    @State private var parsedDate: Date?
    @State private var scannedDateText = ""
    @State private var isIdentifying = false
    @State private var isCapturing = false
    @State private var showFlash = false
    @State private var productName = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var dateFoundAutoAdvance = false
    @State private var analysisResult: ProductAnalysisResult?
    @State private var showManualEntry = false
    @State private var manualDescription = ""
    @State private var showManualDateEntry = false
    @State private var manualDate = Date()
    @State private var selectedStorageZone = "Fridge"

    private let storageZones = ["Fridge", "Freezer", "Pantry"]
    private let storageZoneIcons = ["Fridge": "refrigerator", "Freezer": "snowflake", "Pantry": "cabinet"]

    let onComplete: (FoodItem) -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch captureStep {
            case .product:
                productCaptureView
            case .expiryDate:
                expiryScannerView
            case .reviewing:
                reviewView
            }

            if showFlash {
                Color.white.ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .onAppear {
            cameraService.configure()
            if cameraService.isCameraAvailable {
                cameraService.start()
            }
        }
        .onDisappear {
            cameraService.stop()
        }
        .sheet(isPresented: $showManualEntry) {
            manualEntrySheet
        }
        .sheet(isPresented: $showManualDateEntry) {
            manualDateSheet
        }
    }

    // MARK: - Step 1: Product Capture (Bevel style)

    private var productCaptureView: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Spacer()

                Button { onDismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(.white.opacity(0.15)))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Camera preview or analyzing state
            ZStack {
                if isCapturing || isIdentifying, let productImage {
                    // Show captured image with analyzing overlay
                    Image(uiImage: productImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.black.opacity(0.4))
                        )
                        .overlay(analyzingOverlay)
                } else if cameraService.isCameraAvailable {
                    CameraPreviewView(session: cameraService.session)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(white: 0.1))
                }
            }
            .padding(.horizontal, 12)

            Spacer().frame(height: 24)

            // Instructions
            VStack(spacing: 6) {
                if isIdentifying {
                    Text("Analyzing product...")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    Text("AI is extracting product details")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.6))
                } else {
                    Text("Take a photo")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Capture an image of a food or product.")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            Spacer().frame(height: 28)

            // Bottom controls: Import | Capture | Describe
            HStack(alignment: .top, spacing: 0) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Color(white: 0.2))
                                .frame(width: 56, height: 56)
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        Text("Import")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .disabled(isIdentifying)
                .frame(maxWidth: .infinity)

                Button {
                    Task { await captureProductPhoto() }
                } label: {
                    ZStack {
                        Circle()
                            .strokeBorder(Color(white: 0.5), lineWidth: 4)
                            .frame(width: 72, height: 72)
                        Circle()
                            .fill(.white)
                            .frame(width: 58, height: 58)
                            .scaleEffect(isCapturing ? 0.85 : 1)
                            .animation(.snappy(duration: 0.12), value: isCapturing)
                    }
                }
                .disabled(isCapturing || isIdentifying || !cameraService.isCameraAvailable)
                .opacity(isIdentifying ? 0.4 : 1)
                .frame(maxWidth: .infinity)

                Button { showManualEntry = true } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Color(white: 0.2))
                                .frame(width: 56, height: 56)
                            Image(systemName: "text.cursor")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        Text("Describe")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .disabled(isIdentifying)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    productImage = image
                    cameraService.stop()
                    await analyzeProduct(image)
                    withAnimation(.snappy(duration: 0.25)) {
                        captureStep = .expiryDate
                    }
                }
            }
        }
    }

    // MARK: - Analyzing Overlay

    private var analyzingOverlay: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
                .scaleEffect(1.2)

            Text("Analyzing...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
        .transition(.opacity)
    }

    // MARK: - Manual Entry Sheet

    private var manualEntrySheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                Text("Describe your product")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(WeepColor.textPrimary)

                TextField("", text: $manualDescription, prompt:
                    Text("e.g. Organic whole milk, 1L")
                        .foregroundStyle(WeepColor.placeholder),
                    axis: .vertical
                )
                    .font(WeepFont.body(17))
                    .foregroundStyle(WeepColor.textPrimary)
                    .tint(WeepColor.accent)
                    .lineLimit(3...6)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(WeepColor.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(WeepColor.cardBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, 24)

                Spacer()

                WeepButton(
                    title: "Continue",
                    isEnabled: !manualDescription.trimmingCharacters(in: .whitespaces).isEmpty
                ) {
                    productName = manualDescription.trimmingCharacters(in: .whitespaces)
                    showManualEntry = false
                    withAnimation(.snappy(duration: 0.25)) {
                        captureStep = .expiryDate
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .background(WeepColor.background)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showManualEntry = false }
                        .foregroundColor(WeepColor.textSecondary)
                }
            }
        }
    }

    // MARK: - Manual Date Sheet

    private var manualDateSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                Text("Select expiry date")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(WeepColor.textPrimary)

                DatePicker(
                    "Expiry date",
                    selection: $manualDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(WeepColor.accent)
                                .padding(.horizontal, 24)

                Spacer()

                WeepButton(title: "Set Date") {
                    parsedDate = manualDate
                    showManualDateEntry = false
                    withAnimation(.snappy(duration: 0.25)) {
                        captureStep = .reviewing
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .background(WeepColor.background)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showManualDateEntry = false }
                        .foregroundColor(WeepColor.textSecondary)
                }
            }
        }
    }

    // MARK: - Step 2: Expiry Date Scanner

    private var expiryScannerView: some View {
        ZStack {
            if DateScannerView.isDeviceSupported {
                liveDateScanner
            } else {
                manualExpiryFallback
            }
        }
    }

    private var liveDateScanner: some View {
        ZStack {
            DateScannerView(
                scannedDate: $parsedDate,
                scannedText: $scannedDateText,
                onDateFound: {
                    guard !dateFoundAutoAdvance else { return }
                    dateFoundAutoAdvance = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.snappy(duration: 0.25)) {
                            captureStep = .reviewing
                        }
                    }
                }
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                LinearGradient(colors: [.black.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 120)
                Spacer()
                LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 240)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button {
                        withAnimation(.snappy(duration: 0.25)) {
                            captureStep = .product
                            productImage = nil
                            productName = ""
                            analysisResult = nil
                            dateFoundAutoAdvance = false
                            if cameraService.isCameraAvailable { cameraService.start() }
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    stepIndicator(current: 2, total: 2)
                    Spacer()
                    Button {
                        applyEstimatedExpiryFromAI()
                        withAnimation(.snappy(duration: 0.25)) { captureStep = .reviewing }
                    } label: {
                        Text("Skip")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()

                // Scan frame
                ScanFrameView()
                    .frame(height: 100)
                    .padding(.horizontal, 36)
                    .allowsHitTesting(false)

                Spacer()

                // Status
                VStack(spacing: 16) {
                    if let parsedDate {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(WeepColor.accent)
                            Text(parsedDate, format: .dateTime.day().month(.wide).year())
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(.white.opacity(0.15)))
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        VStack(spacing: 6) {
                            Text("Point at the expiry date")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            Text("It will be detected automatically")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.6))

                            if !scannedDateText.isEmpty {
                                Text("Reading: \(scannedDateText)")
                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.4))
                                    .lineLimit(1)
                                    .padding(.top, 4)
                            }
                        }
                    }

                    Button { showManualDateEntry = true } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 14))
                            Text("Enter date manually")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(.white.opacity(0.15)))
                    }
                }
                .animation(.snappy(duration: 0.25), value: parsedDate != nil)
                .padding(.bottom, 40)
            }
        }
    }

    private var manualExpiryFallback: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        withAnimation(.snappy(duration: 0.25)) {
                            captureStep = .product
                            productImage = nil
                            productName = ""
                            analysisResult = nil
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    stepIndicator(current: 2, total: 2)
                    Spacer()
                    Button {
                        applyEstimatedExpiryFromAI()
                        withAnimation(.snappy(duration: 0.25)) { captureStep = .reviewing }
                    } label: {
                        Text("Skip")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()

                ScanFrameView()
                    .frame(height: 120)
                    .padding(.horizontal, 36)

                Spacer()

                VStack(spacing: 16) {
                    Text("No live scanner available")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Enter the date manually instead")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.6))

                    Button { showManualDateEntry = true } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 14))
                            Text("Enter date manually")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(.white.opacity(0.15)))
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Review

    private var reviewView: some View {
        ZStack {
            WeepColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        withAnimation(.snappy(duration: 0.25)) {
                            captureStep = .expiryDate
                            parsedDate = nil
                            scannedDateText = ""
                            dateFoundAutoAdvance = false
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(WeepColor.textPrimary)
                            .frame(width: 36, height: 36)
                    }
                    Spacer()
                    Text("Review")
                        .font(WeepFont.bodyMedium(17))
                        .foregroundColor(WeepColor.textPrimary)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 8)

                        if let productImage {
                            Image(uiImage: productImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 160, height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                        }

                        if isIdentifying {
                            VStack(spacing: 8) {
                                ProgressView()
                                    .tint(WeepColor.accent)
                                Text("AI is analyzing...")
                                    .font(WeepFont.caption(14))
                                    .foregroundColor(WeepColor.textSecondary)
                            }
                        }

                        if let result = analysisResult, !isIdentifying {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12))
                                    .foregroundColor(WeepColor.accent)
                                Text("AI Analysis Complete")
                                    .font(WeepFont.caption(12))
                                    .foregroundColor(WeepColor.accent)
                                if let brand = result.brand {
                                    Text("· \(brand)")
                                        .font(WeepFont.caption(12))
                                        .foregroundColor(WeepColor.textSecondary)
                                }
                            }
                        }

                        // Name field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Product name")
                                .font(WeepFont.caption(13))
                                .foregroundColor(WeepColor.textSecondary)

                            TextField("", text: $productName, prompt:
                                Text("What is this product?")
                                    .foregroundStyle(WeepColor.placeholder)
                            )
                                .font(WeepFont.bodyMedium(17))
                                .foregroundStyle(WeepColor.textPrimary)
                                .tint(WeepColor.accent)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(WeepColor.cardBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(WeepColor.cardBorder, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 24)

                        // Expiry date
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Expiry date")
                                .font(WeepFont.caption(13))
                                .foregroundColor(WeepColor.textSecondary)

                            HStack {
                                Image(systemName: "calendar")
                                    .font(.system(size: 16))
                                    .foregroundColor(WeepColor.accent)

                                if parsedDate != nil {
                                    DatePicker(
                                        "",
                                        selection: Binding(
                                            get: { parsedDate ?? Date() },
                                            set: { parsedDate = $0 }
                                        ),
                                        displayedComponents: .date
                                    )
                                    .labelsHidden()
                                    .tint(WeepColor.accent)
                                    
                                    Spacer()

                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(WeepColor.accent)
                                } else {
                                    Button {
                                        parsedDate = Date()
                                    } label: {
                                        Text("Tap to set date")
                                            .font(WeepFont.body(16))
                                            .foregroundColor(WeepColor.accent)
                                    }
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(WeepColor.cardBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(WeepColor.cardBorder, lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 24)

                        // Storage zone
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Storage space")
                                .font(WeepFont.caption(13))
                                .foregroundColor(WeepColor.textSecondary)

                            HStack(spacing: 8) {
                                ForEach(storageZones, id: \.self) { zone in
                                    let isSelected = selectedStorageZone == zone
                                    Button {
                                        WeepHaptics.light()
                                        withAnimation(.snappy(duration: 0.15)) {
                                            selectedStorageZone = zone
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: storageZoneIcons[zone] ?? "questionmark")
                                                .font(.system(size: 14))
                                            Text(zone)
                                                .font(WeepFont.bodyMedium(14))
                                        }
                                        .foregroundColor(isSelected ? .white : WeepColor.textPrimary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(isSelected ? WeepColor.accent : WeepColor.cardBackground)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .strokeBorder(isSelected ? Color.clear : WeepColor.cardBorder, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        Spacer(minLength: 100)
                    }
                }

                WeepButton(
                    title: "Add to my kitchen",
                    isEnabled: !productName.trimmingCharacters(in: .whitespaces).isEmpty && !isIdentifying
                ) {
                    WeepHaptics.success()
                    onComplete(buildFoodItem())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .animation(.snappy(duration: 0.25), value: isIdentifying)
    }

    // MARK: - Actions

    private func captureProductPhoto() async {
        guard !isCapturing else { return }
        isCapturing = true
        WeepHaptics.medium()

        withAnimation(.easeOut(duration: 0.08)) { showFlash = true }
        withAnimation(.easeIn(duration: 0.15).delay(0.1)) { showFlash = false }

        if let image = await cameraService.capturePhoto() {
            withAnimation(.snappy(duration: 0.25)) {
                productImage = image
            }
            cameraService.stop()
            isCapturing = false

            // Show analyzing overlay while AI works
            await analyzeProduct(image)

            withAnimation(.snappy(duration: 0.25)) {
                captureStep = .expiryDate
            }
        } else {
            isCapturing = false
        }
    }

    private func applyEstimatedExpiryFromAI() {
        guard parsedDate == nil,
              let days = analysisResult?.estimatedShelfLifeDays,
              days > 0 else { return }
        parsedDate = Calendar.current.date(byAdding: .day, value: days, to: Date())
    }

    private func analyzeProduct(_ image: UIImage) async {
        isIdentifying = true
        async let claudeResult = ClaudeProductAnalyzer.analyze(image: image)
        async let visionFallback = ProductIdentifier.identify(from: image)

        if let result = await claudeResult {
            withAnimation(.snappy(duration: 0.25)) {
                analysisResult = result
                productName = result.name
                if let zone = result.suggestedStorageZone, storageZones.contains(zone) {
                    selectedStorageZone = zone
                }
                isIdentifying = false
            }
        } else {
            let fallbackName = await visionFallback
            withAnimation(.snappy(duration: 0.25)) {
                if !fallbackName.isEmpty { productName = fallbackName }
                isIdentifying = false
            }
        }
    }

    private func buildFoodItem() -> FoodItem {
        var item = FoodItem(
            name: productName.trimmingCharacters(in: .whitespaces),
            expiryDate: parsedDate,
            productImageData: productImage?.jpegData(compressionQuality: 0.7),
            storageZone: selectedStorageZone
        )
        if let result = analysisResult {
            ClaudeProductAnalyzer.applyAnalysis(result, to: &item)
            item.name = productName.trimmingCharacters(in: .whitespaces)
        }
        return item
    }

    // MARK: - UI Components

    private func stepIndicator(current: Int, total: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(1...total, id: \.self) { step in
                Capsule()
                    .fill(step <= current ? Color.white : Color.white.opacity(0.3))
                    .frame(width: step == current ? 24 : 8, height: 4)
            }
        }
    }

}

// MARK: - Scan Frame View

struct ScanFrameView: View {
    private let cornerRadius: CGFloat = 14
    private let cornerLength: CGFloat = 28
    private let lineWidth: CGFloat = 3
    @State private var scanOffset: CGFloat = -0.4

    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)

            ZStack {
                // Subtle full border
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)

                // Corner accents — 4 separate stroked paths clipped to corners
                cornerPath(rect: rect, corner: .topLeft)
                cornerPath(rect: rect, corner: .topRight)
                cornerPath(rect: rect, corner: .bottomRight)
                cornerPath(rect: rect, corner: .bottomLeft)

                // Scan line
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, WeepColor.accent.opacity(0.5), .clear],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(height: 2)
                    .offset(y: geo.size.height * scanOffset)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                scanOffset = 0.4
            }
        }
    }

    private enum Corner { case topLeft, topRight, bottomRight, bottomLeft }

    private func cornerPath(rect: CGRect, corner: Corner) -> some View {
        Path { path in
            let r = cornerRadius
            let l = cornerLength

            switch corner {
            case .topLeft:
                path.move(to: CGPoint(x: 0, y: l))
                path.addLine(to: CGPoint(x: 0, y: r))
                path.addArc(center: CGPoint(x: r, y: r), radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
                path.addLine(to: CGPoint(x: l, y: 0))

            case .topRight:
                path.move(to: CGPoint(x: rect.width - l, y: 0))
                path.addLine(to: CGPoint(x: rect.width - r, y: 0))
                path.addArc(center: CGPoint(x: rect.width - r, y: r), radius: r, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
                path.addLine(to: CGPoint(x: rect.width, y: l))

            case .bottomRight:
                path.move(to: CGPoint(x: rect.width, y: rect.height - l))
                path.addLine(to: CGPoint(x: rect.width, y: rect.height - r))
                path.addArc(center: CGPoint(x: rect.width - r, y: rect.height - r), radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
                path.addLine(to: CGPoint(x: rect.width - l, y: rect.height))

            case .bottomLeft:
                path.move(to: CGPoint(x: l, y: rect.height))
                path.addLine(to: CGPoint(x: r, y: rect.height))
                path.addArc(center: CGPoint(x: r, y: rect.height - r), radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
                path.addLine(to: CGPoint(x: 0, y: rect.height - l))
            }
        }
        .stroke(.white, lineWidth: lineWidth)
    }
}
