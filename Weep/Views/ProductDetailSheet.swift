import SwiftUI

struct ProductDetailSheet: View {
    @State var item: FoodItem
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    @State private var showDeleteAlert = false

    // Editable fields
    @State private var editName = ""
    @State private var editBrand = ""
    @State private var editStorageZone = ""
    @State private var editExpiryDate = Date()
    @State private var hasExpiryDate = false
    @State private var editDescription = ""
    @State private var editStorageTips = ""

    private let store = KitchenStore.shared

    var body: some View {
        ZStack(alignment: .top) {
            WeepColor.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    heroImage

                    VStack(spacing: 20) {
                        if isEditing {
                            editingContent
                        } else {
                            readOnlyContent
                        }
                    }
                    .padding(.top, isEditing ? 8 : 16)
                    .padding(.bottom, 40)
                    .background(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 28, bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0, topTrailingRadius: 28
                        )
                        .fill(WeepColor.background)
                        .offset(y: -28)
                    )
                }
            }

            topBar
        }
        .alert("Delete \(item.name)?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                store.removeItem(item)
                dismiss()
            }
        } message: {
            Text("This item will be permanently removed from your kitchen.")
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(.ultraThinMaterial).environment(\.colorScheme, .dark))
            }

            Spacer()

            Spacer()

            Menu {
                Button {
                    prepareEditing()
                    withAnimation { isEditing = true }
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Divider()
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(.ultraThinMaterial).environment(\.colorScheme, .dark))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 36)
    }

    // MARK: - Hero Image

    private var heroImage: some View {
        Group {
            if let imageData = item.productImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 380)
                    .clipped()
            } else {
                ZStack {
                    WeepColor.accentLight
                    Image(systemName: "fork.knife")
                        .font(.system(size: 48, weight: .ultraLight))
                        .foregroundColor(WeepColor.accent)
                }
                .frame(height: 280)
            }
        }
    }

    // MARK: - Read Only Content

    private var readOnlyContent: some View {
        VStack(spacing: 20) {
            // Time + name
            VStack(alignment: .leading, spacing: 8) {
                Text(item.dateAdded, format: .dateTime.hour().minute())
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(WeepColor.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(WeepColor.cardBackground))
                    .overlay(Capsule().strokeBorder(WeepColor.cardBorder, lineWidth: 1))
                    .padding(.top, -14)

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(WeepColor.textPrimary)
                        if let brand = item.brand {
                            Text(brand)
                                .font(WeepFont.body(16))
                                .foregroundColor(WeepColor.textSecondary)
                        }
                    }
                    Spacer()
                    Image(systemName: item.freshnessStatus.icon)
                        .font(.system(size: 24))
                        .foregroundColor(freshnessColor)
                }
            }
            .padding(.horizontal, 24)

            // Freshness badge
            freshnessBadge
                .padding(.horizontal, 24)

            // Measurement
            if item.servingSize != nil || item.weight != nil {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Measurement")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(WeepColor.textPrimary)

                    HStack(spacing: 10) {
                        measurementPill("Serving", selected: true)
                        measurementPill("Package", selected: false)
                        if let w = item.weight {
                            measurementPill(w, selected: false)
                        }
                    }

                    if let serving = item.servingSize {
                        HStack {
                            Text("Serving size")
                                .font(WeepFont.body(15))
                                .foregroundColor(WeepColor.textPrimary)
                            Spacer()
                            Text(serving)
                                .font(WeepFont.bodyMedium(15))
                                .foregroundColor(WeepColor.textSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(WeepColor.cardBorder, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            // Calories
            if let calories = item.nutrition?.calories {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(WeepColor.background).frame(width: 48, height: 48)
                        Image(systemName: "flame.fill")
                            .font(.system(size: 20))
                            .foregroundColor(WeepColor.textPrimary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Calories")
                            .font(WeepFont.caption(14))
                            .foregroundColor(WeepColor.textSecondary)
                        Text(calories)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(WeepColor.textPrimary)
                    }
                    Spacer()
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(WeepColor.cardBackground)
                        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
                )
                .padding(.horizontal, 24)
            }

            // Macros
            if let n = item.nutrition {
                HStack(spacing: 10) {
                    if let p = n.protein { macroCard(label: "Protein", value: p, color: WeepColor.alertRed, icon: "flame.fill") }
                    if let c = n.totalCarbohydrates { macroCard(label: "Carbs", value: c, color: WeepColor.alertAmber, icon: "leaf.fill") }
                    if let f = n.totalFat { macroCard(label: "Fat", value: f, color: Color(hex: 0x5B9BD5), icon: "drop.fill") }
                }
                .padding(.horizontal, 24)
            }

            // Nutrition table
            if let nutrition = item.nutrition, nutrition.hasAnyData {
                nutritionTable(nutrition)
            }

            // Ingredients
            if let ingredients = item.ingredients, !ingredients.isEmpty {
                sectionCard(title: "Ingredients") {
                    Text(ingredients.joined(separator: ", "))
                        .font(WeepFont.body(15))
                        .foregroundColor(WeepColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Allergens
            if let allergens = item.allergens, !allergens.isEmpty {
                sectionCard(title: "Allergens") {
                    FlowLayoutDetail(items: allergens) { allergen in
                        Text(allergen)
                            .font(WeepFont.caption(13))
                            .foregroundColor(WeepColor.alertRed)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(WeepColor.alertRed.opacity(0.1)))
                    }
                }
            }

            // Storage tips
            if let tips = item.storageTips {
                sectionCard(title: "Storage Tips") {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 14))
                            .foregroundColor(WeepColor.accentWarm)
                            .padding(.top, 2)
                        Text(tips)
                            .font(WeepFont.body(15))
                            .foregroundColor(WeepColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            // About
            if let desc = item.productDescription {
                sectionCard(title: "About") {
                    Text(desc)
                        .font(WeepFont.body(15))
                        .foregroundColor(WeepColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Bottom buttons
            Spacer().frame(height: 8)

            HStack(spacing: 12) {
                Button {
                    prepareEditing()
                    withAnimation { isEditing = true }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                        Text("Edit")
                            .font(WeepFont.bodyMedium(16))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundColor(WeepColor.textPrimary)
                    .background(Capsule().strokeBorder(WeepColor.cardBorder, lineWidth: 1))
                }

                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .medium))
                        Text("Delete")
                            .font(WeepFont.bodyMedium(16))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundColor(.white)
                    .background(Capsule().fill(Color.red))
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Editing Content

    private var editingContent: some View {
        VStack(spacing: 18) {
            // Header
            HStack {
                Button("Cancel") { withAnimation { isEditing = false } }
                    .font(WeepFont.body(17))
                    .foregroundColor(WeepColor.textSecondary)
                Spacer()
                Text("Edit Item")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(WeepColor.textPrimary)
                Spacer()
                Button("Save") { saveEdits() }
                    .font(WeepFont.bodyMedium(17))
                    .foregroundColor(WeepColor.accent)
            }
            .padding(.horizontal, 24)
            .padding(.top, -4)

            // Name
            formSection(title: "Product name") {
                TextField("", text: $editName, prompt:
                    Text("e.g. Greek Yogurt").foregroundStyle(WeepColor.placeholder)
                )
                    .font(WeepFont.bodyMedium(17))
                    .foregroundStyle(WeepColor.textPrimary)
                    .tint(WeepColor.accent)
            }

            // Brand
            formSection(title: "Brand") {
                TextField("", text: $editBrand, prompt:
                    Text("e.g. Nestlé, Danone").foregroundStyle(WeepColor.placeholder)
                )
                    .font(WeepFont.body(17))
                    .foregroundStyle(WeepColor.textPrimary)
                    .tint(WeepColor.accent)
            }

            // Storage zone
            formSection(title: "Storage zone") {
                HStack {
                    Text(editStorageZone)
                        .font(WeepFont.bodyMedium(17))
                        .foregroundColor(WeepColor.textPrimary)
                    Spacer()
                    Picker("", selection: $editStorageZone) {
                        Text("Fridge").tag("Fridge")
                        Text("Freezer").tag("Freezer")
                        Text("Pantry").tag("Pantry")
                    }
                    .pickerStyle(.menu)
                    .tint(WeepColor.accent)
                }
            }

            // Expiry date
            VStack(alignment: .leading, spacing: 6) {
                Text("Expiry date")
                    .font(WeepFont.caption(14))
                    .foregroundColor(WeepColor.textSecondary)
                    .padding(.horizontal, 24)

                VStack(spacing: 0) {
                    Toggle("Has expiry date", isOn: $hasExpiryDate.animation())
                        .font(WeepFont.body(16))
                        .foregroundColor(WeepColor.textPrimary)
                        .tint(WeepColor.accent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                    if hasExpiryDate {
                        Divider().padding(.horizontal, 16)
                        DatePicker(
                            "Select date",
                            selection: $editExpiryDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .tint(WeepColor.accent)
                        .environment(\.colorScheme, .light)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(WeepColor.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(WeepColor.cardBorder, lineWidth: 1)
                )
                .padding(.horizontal, 24)
            }

            // Description
            if item.productDescription != nil {
                formSection(title: "Description") {
                    TextField("", text: $editDescription, prompt:
                        Text("Describe the product").foregroundStyle(WeepColor.placeholder),
                        axis: .vertical
                    )
                        .font(WeepFont.body(15))
                        .foregroundStyle(WeepColor.textPrimary)
                        .tint(WeepColor.accent)
                        .lineLimit(2...6)
                }
            }

            // Storage tips
            if item.storageTips != nil {
                formSection(title: "Storage tips") {
                    TextField("", text: $editStorageTips, prompt:
                        Text("How to store this product").foregroundStyle(WeepColor.placeholder),
                        axis: .vertical
                    )
                        .font(WeepFont.body(15))
                        .foregroundStyle(WeepColor.textPrimary)
                        .tint(WeepColor.accent)
                        .lineLimit(2...6)
                }
            }
        }
    }

    // MARK: - Components

    private func formSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(WeepFont.caption(14))
                .foregroundColor(WeepColor.textSecondary)
                .padding(.horizontal, 24)

            content()
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(WeepColor.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(WeepColor.cardBorder, lineWidth: 1)
                )
                .padding(.horizontal, 24)
        }
    }

    private func measurementPill(_ text: String, selected: Bool) -> some View {
        Text(text)
            .font(.system(size: 15, weight: selected ? .semibold : .regular))
            .foregroundColor(selected ? .white : WeepColor.textPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Capsule().fill(selected ? WeepColor.buttonPrimary : Color.clear))
            .overlay(Capsule().strokeBorder(selected ? Color.clear : WeepColor.cardBorder, lineWidth: 1))
    }

    private func macroCard(label: String, value: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 10)).foregroundColor(color)
                Text(label).font(WeepFont.caption(13)).foregroundColor(WeepColor.textSecondary)
            }
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(WeepColor.textPrimary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(WeepColor.cardBackground)
                .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
        )
    }

    private var freshnessBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: item.freshnessStatus.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(freshnessColor)
            if let days = item.daysUntilExpiry {
                Text(expiryText(days: days))
                    .font(WeepFont.bodyMedium(15))
                    .foregroundColor(freshnessColor)
            } else {
                Text("No expiry date set")
                    .font(WeepFont.bodyMedium(15))
                    .foregroundColor(WeepColor.textSecondary)
            }
            Spacer()
            if let d = item.expiryDate {
                Text(d, format: .dateTime.day().month(.abbreviated).year())
                    .font(WeepFont.caption(13))
                    .foregroundColor(WeepColor.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(freshnessColor.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(freshnessColor.opacity(0.2), lineWidth: 1))
    }

    private func nutritionTable(_ n: NutritionInfo) -> some View {
        sectionCard(title: "Nutrition Facts") {
            VStack(spacing: 0) {
                nRow("Total Fat", n.totalFat, bold: true)
                nRow("  Saturated Fat", n.saturatedFat)
                nRow("  Trans Fat", n.transFat)
                nRow("Cholesterol", n.cholesterol, bold: true)
                nRow("Sodium", n.sodium, bold: true)
                nRow("Total Carbs", n.totalCarbohydrates, bold: true)
                nRow("  Dietary Fiber", n.dietaryFiber)
                nRow("  Total Sugars", n.totalSugars)
                nRow("Protein", n.protein, bold: true)

                let hasVit = [n.vitaminA, n.vitaminC, n.vitaminD, n.calcium, n.iron, n.potassium].contains { $0 != nil }
                if hasVit {
                    Divider().overlay(WeepColor.divider).padding(.vertical, 6)
                    nRow("Vitamin A", n.vitaminA)
                    nRow("Vitamin C", n.vitaminC)
                    nRow("Vitamin D", n.vitaminD)
                    nRow("Calcium", n.calcium)
                    nRow("Iron", n.iron)
                    nRow("Potassium", n.potassium)
                }
            }
        }
    }

    @ViewBuilder
    private func nRow(_ label: String, _ value: String?, bold: Bool = false) -> some View {
        if let value {
            HStack {
                Text(label).font(bold ? WeepFont.bodyMedium(14) : WeepFont.body(14)).foregroundColor(WeepColor.textPrimary)
                Spacer()
                Text(value).font(WeepFont.body(14)).foregroundColor(WeepColor.textSecondary)
            }
            .padding(.vertical, 3)
        }
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(WeepColor.textPrimary)
            content()
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(WeepColor.cardBackground)
                        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
                )
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Actions

    private func prepareEditing() {
        editName = item.name
        editBrand = item.brand ?? ""
        editStorageZone = item.storageZone
        hasExpiryDate = item.expiryDate != nil
        editExpiryDate = item.expiryDate ?? Date()
        editDescription = item.productDescription ?? ""
        editStorageTips = item.storageTips ?? ""
    }

    private func saveEdits() {
        let trimmed = editName.trimmingCharacters(in: .whitespaces)
        item.name = trimmed.isEmpty ? item.name : trimmed
        item.brand = editBrand.trimmingCharacters(in: .whitespaces).isEmpty ? nil : editBrand.trimmingCharacters(in: .whitespaces)
        item.storageZone = editStorageZone
        item.expiryDate = hasExpiryDate ? editExpiryDate : nil
        if item.productDescription != nil {
            item.productDescription = editDescription.trimmingCharacters(in: .whitespaces).isEmpty ? nil : editDescription.trimmingCharacters(in: .whitespaces)
        }
        if item.storageTips != nil {
            item.storageTips = editStorageTips.trimmingCharacters(in: .whitespaces).isEmpty ? nil : editStorageTips.trimmingCharacters(in: .whitespaces)
        }
        store.updateItem(item)
        withAnimation { isEditing = false }
    }

    // MARK: - Helpers

    private var freshnessColor: Color {
        switch item.freshnessStatus {
        case .veryFresh: return WeepColor.accent
        case .fresh: return WeepColor.primaryGreenLight
        case .expiringSoon: return WeepColor.alertAmber
        case .expired: return WeepColor.alertRed
        case .unknown: return WeepColor.textSecondary
        }
    }

    private func expiryText(days: Int) -> String {
        if days < 0 { return "Expired \(-days) days ago" }
        if days == 0 { return "Expires today" }
        if days == 1 { return "Expires tomorrow" }
        return "Expires in \(days) days"
    }
}

// MARK: - Flow Layout

struct FlowLayoutDetail<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content
    @State private var totalHeight: CGFloat = .zero

    var body: some View {
        GeometryReader { geometry in generateContent(in: geometry) }
            .frame(height: totalHeight)
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                content(item)
                    .padding(.trailing, 6).padding(.bottom, 6)
                    .alignmentGuide(.leading) { d in
                        if abs(width - d.width) > geometry.size.width { width = 0; height -= d.height }
                        let result = width
                        if item == items.last { width = 0 } else { width -= d.width }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if item == items.last { height = 0 }
                        return result
                    }
            }
        }
        .background(GeometryReader { g -> Color in
            DispatchQueue.main.async { totalHeight = g.size.height }
            return .clear
        })
    }
}
