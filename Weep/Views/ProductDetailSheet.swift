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
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    heroImage

                    VStack(spacing: 0) {
                        if isEditing {
                            editingContent
                        } else {
                            readOnlyContent
                        }
                    }
                    .padding(.top, isEditing ? 8 : 20)
                    .padding(.bottom, 40)
                    .background(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 24, bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0, topTrailingRadius: 24
                        )
                        .fill(Color(.systemGroupedBackground))
                        .offset(y: -24)
                    )
                }
            }

            topBar
        }
        .tint(nil)
        .alert("Delete \(item.name)?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                store.removeItem(item, reason: .deleted)
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
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(.ultraThinMaterial).environment(\.colorScheme, .dark))
            }

            Spacer()

            Menu {
                Button {
                    prepareEditing()
                    withAnimation(.snappy(duration: 0.25)) { isEditing = true }
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button {
                    WeepHaptics.success()
                    store.removeItem(item, reason: .used)
                    dismiss()
                } label: {
                    Label("Mark as used", systemImage: "checkmark.circle")
                }
                Divider()
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
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
                    .frame(height: 360)
                    .clipped()
            } else {
                ZStack {
                    Color(.tertiarySystemFill)
                    Image(systemName: "fork.knife")
                        .font(.system(size: 44, weight: .ultraLight))
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .frame(height: 260)
            }
        }
    }

    // MARK: - Read Only Content

    private var readOnlyContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header: name + brand + freshness icon
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(.label))

                if let brand = item.brand {
                    Text(brand)
                        .font(.system(size: 16))
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
            .padding(.horizontal, 24)

            // Freshness badge
            if item.expiryDate != nil {
                freshnessBadge
                    .padding(.horizontal, 24)
            }

            // Nutrition section
            if let n = item.nutrition, n.hasAnyData {
                VStack(alignment: .leading, spacing: 14) {
                    // Calories card
                    if let cal = n.calories {
                        caloriesCard(cal)
                    }

                    // Macro cards row
                    let hasMacros = n.protein != nil || n.totalCarbohydrates != nil || n.totalFat != nil
                    if hasMacros {
                        HStack(spacing: 10) {
                            if let p = n.protein { macroCard(label: "Protein", value: p, icon: "🥩") }
                            if let c = n.totalCarbohydrates { macroCard(label: "Carbs", value: c, icon: "🌾") }
                            if let f = n.totalFat { macroCard(label: "Fats", value: f, icon: "💧") }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            // Detailed nutrition table
            if let nutrition = item.nutrition, nutrition.hasAnyData {
                nutritionTable(nutrition)
            }

            // Ingredients
            if let ingredients = item.ingredients, !ingredients.isEmpty {
                sectionBlock(title: "Ingredients") {
                    Text(ingredients.joined(separator: ", "))
                        .font(.system(size: 15))
                        .foregroundColor(Color(.label))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Allergens
            if let allergens = item.allergens, !allergens.isEmpty {
                sectionBlock(title: "Allergens") {
                    FlowLayoutDetail(items: allergens) { allergen in
                        Text(allergen)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(WeepColor.alertRed)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(WeepColor.alertRed.opacity(0.08))
                            )
                    }
                }
            }

            // Storage tips
            if let tips = item.storageTips {
                sectionBlock(title: "Storage Tips") {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 13))
                            .foregroundColor(WeepColor.accentWarm)
                            .padding(.top, 2)
                        Text(tips)
                            .font(.system(size: 15))
                            .foregroundColor(Color(.label))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            // About
            if let desc = item.productDescription {
                sectionBlock(title: "About") {
                    Text(desc)
                        .font(.system(size: 15))
                        .foregroundColor(Color(.label))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Calories Card

    private func caloriesCard(_ calories: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 48, height: 48)
                Image(systemName: "flame.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(.label))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Calories")
                    .font(.system(size: 14))
                    .foregroundColor(Color(.secondaryLabel))
                Text(calories)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Color(.label))
            }

            Spacer()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Macro Card

    private func macroCard(label: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(icon).font(.system(size: 12))
                Text(label)
                    .font(.system(size: 13))
                    .foregroundColor(Color(.secondaryLabel))
            }
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Color(.label))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Freshness Badge

    private var freshnessBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: item.freshnessStatus.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(freshnessColor)

            if let days = item.daysUntilExpiry {
                Text(expiryText(days: days))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(freshnessColor)
            }

            Spacer()

            if let d = item.expiryDate {
                Text(d, format: .dateTime.day().month(.abbreviated).year())
                    .font(.system(size: 13))
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(freshnessColor.opacity(0.08))
        )
    }

    // MARK: - Nutrition Table

    private func nutritionTable(_ n: NutritionInfo) -> some View {
        sectionBlock(title: "Nutrition Facts") {
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
                    Divider().padding(.vertical, 8)
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
                Text(label)
                    .font(.system(size: 14, weight: bold ? .medium : .regular))
                    .foregroundColor(Color(.label))
                Spacer()
                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(Color(.secondaryLabel))
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Section Block

    private func sectionBlock<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(.label))

            content()
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Editing Content

    private var editingContent: some View {
        VStack(spacing: 18) {
            HStack {
                Button("Cancel") { withAnimation(.snappy(duration: 0.25)) { isEditing = false } }
                    .font(.system(size: 17))
                    .foregroundColor(Color(.secondaryLabel))
                Spacer()
                Text("Edit Item")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(.label))
                Spacer()
                Button("Save") { saveEdits() }
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(WeepColor.accent)
            }
            .padding(.horizontal, 24)
            .padding(.top, -4)

            formSection(title: "Product name") {
                TextField("", text: $editName, prompt:
                    Text("e.g. Greek Yogurt").foregroundStyle(Color(.placeholderText))
                )
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color(.label))
                    .tint(WeepColor.accent)
            }

            formSection(title: "Brand") {
                TextField("", text: $editBrand, prompt:
                    Text("e.g. Nestlé, Danone").foregroundStyle(Color(.placeholderText))
                )
                    .font(.system(size: 17))
                    .foregroundStyle(Color(.label))
                    .tint(WeepColor.accent)
            }

            formSection(title: "Storage zone") {
                HStack {
                    Text(editStorageZone)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Color(.label))
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

            VStack(alignment: .leading, spacing: 6) {
                Text("Expiry date")
                    .font(.system(size: 14))
                    .foregroundColor(Color(.secondaryLabel))
                    .padding(.horizontal, 24)

                VStack(spacing: 0) {
                    Toggle("Has expiry date", isOn: $hasExpiryDate.animation())
                        .font(.system(size: 16))
                        .foregroundColor(Color(.label))
                        .tint(WeepColor.accent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                    if hasExpiryDate {
                        Divider().padding(.horizontal, 16)
                        DatePicker("Select date", selection: $editExpiryDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .tint(WeepColor.accent)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .padding(.horizontal, 24)
            }

            if item.productDescription != nil {
                formSection(title: "Description") {
                    TextField("", text: $editDescription, prompt:
                        Text("Describe the product").foregroundStyle(Color(.placeholderText)),
                        axis: .vertical
                    )
                        .font(.system(size: 15))
                        .foregroundStyle(Color(.label))
                        .tint(WeepColor.accent)
                        .lineLimit(2...6)
                }
            }

            if item.storageTips != nil {
                formSection(title: "Storage tips") {
                    TextField("", text: $editStorageTips, prompt:
                        Text("How to store this product").foregroundStyle(Color(.placeholderText)),
                        axis: .vertical
                    )
                        .font(.system(size: 15))
                        .foregroundStyle(Color(.label))
                        .tint(WeepColor.accent)
                        .lineLimit(2...6)
                }
            }
        }
    }

    // MARK: - Form Section

    private func formSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(Color(.secondaryLabel))
                .padding(.horizontal, 24)

            content()
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .padding(.horizontal, 24)
        }
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
        withAnimation(.snappy(duration: 0.25)) { isEditing = false }
    }

    // MARK: - Helpers

    private var freshnessColor: Color {
        switch item.freshnessStatus {
        case .veryFresh: return WeepColor.accent
        case .fresh: return WeepColor.primaryGreenLight
        case .expiringSoon: return WeepColor.alertAmber
        case .expired: return WeepColor.alertRed
        case .unknown: return Color(.secondaryLabel)
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

private struct FlowHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct FlowLayoutDetail<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content
    @State private var totalHeight: CGFloat = .zero

    var body: some View {
        GeometryReader { geometry in generateContent(in: geometry) }
            .frame(height: totalHeight)
            .onPreferenceChange(FlowHeightPreferenceKey.self) { totalHeight = $0 }
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
        .background(GeometryReader { g in
            Color.clear.preference(key: FlowHeightPreferenceKey.self, value: g.size.height)
        })
    }
}
