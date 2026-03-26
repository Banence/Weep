import SwiftUI

struct KitchenZonesScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var newZoneName = ""
    @State private var isAddingZone = false
    @FocusState private var isNewZoneFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 40)

                    Text("Set up your\nkitchen zones")
                        .font(WeepFont.largeTitle(32))
                        .foregroundColor(WeepColor.textPrimary)
                        .staggeredAppear(delay: 0.1)

                    Spacer().frame(height: 6)

                    Text("Where does your food live?")
                        .font(WeepFont.caption())
                        .foregroundColor(WeepColor.textSecondary)
                        .staggeredAppear(delay: 0.15)

                    Spacer().frame(height: 32)

                    VStack(spacing: 10) {
                        ForEach($viewModel.storageZones) { $zone in
                            ZoneRow(zone: $zone)
                        }

                        if isAddingZone {
                            HStack {
                                ZStack(alignment: .leading) {
                                    if newZoneName.isEmpty {
                                        Text("e.g. Garage, Wine rack")
                                            .font(WeepFont.body())
                                            .foregroundColor(WeepColor.placeholder)
                                    }
                                    TextField("", text: $newZoneName)
                                        .font(WeepFont.body())
                                        .foregroundColor(WeepColor.textPrimary)
                                        .focused($isNewZoneFieldFocused)
                                        .onSubmit { addZone() }
                                }

                                Button("Add") { addZone() }
                                    .font(WeepFont.bodyMedium())
                                    .foregroundColor(
                                        newZoneName.trimmingCharacters(in: .whitespaces).isEmpty
                                            ? WeepColor.textSecondary
                                            : WeepColor.textPrimary
                                    )
                                    .disabled(newZoneName.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(WeepColor.cardBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(WeepColor.cardBorder, lineWidth: 1)
                            )
                            .transition(.opacity)
                        }
                    }
                    .staggeredAppear(delay: 0.2)

                    if !isAddingZone {
                        Spacer().frame(height: 20)

                        Button {
                            WeepHaptics.light()
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isAddingZone = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                isNewZoneFieldFocused = true
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Add a zone")
                                    .font(WeepFont.caption())
                            }
                            .foregroundColor(WeepColor.textSecondary)
                        }
                        .staggeredAppear(delay: 0.3)
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            BottomButtonBar {
                WeepButton(title: "Continue") { onContinue() }
            }
        }
    }

    private func addZone() {
        let name = newZoneName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        WeepHaptics.success()
        viewModel.storageZones.append(StorageZone(id: UUID(), name: name, icon: "tray.fill", isEnabled: true))
        newZoneName = ""
        withAnimation(.easeInOut(duration: 0.25)) { isAddingZone = false }
    }
}

struct ZoneRow: View {
    @Binding var zone: StorageZone

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: zone.icon)
                .font(.system(size: 18))
                .foregroundColor(zone.isEnabled ? WeepColor.textPrimary : WeepColor.iconMuted)
                .frame(width: 28)

            Text(zone.name)
                .font(WeepFont.body())
                .foregroundColor(WeepColor.textPrimary)

            Spacer()

            Toggle("", isOn: $zone.isEnabled)
                .labelsHidden()
                .tint(WeepColor.accent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(WeepColor.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(WeepColor.cardBorder, lineWidth: 1)
        )
    }
}
