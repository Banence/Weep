import SwiftUI
import ClerkKit
import PhotosUI

struct AccountDetailView: View {
    @Environment(Clerk.self) private var clerk
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isUploadingPhoto = false

    // Editable name fields
    @State private var editFirstName = ""
    @State private var editLastName = ""
    @State private var isEditingName = false
    @State private var isSavingName = false
    @State private var nameError: String?

    private var user: User? { clerk.user }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    avatarSection
                        .padding(.top, 8)

                    personalInfoSection

                    connectedAccountsSection

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Account details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(.label))
                    }
                }
            }
            .onChange(of: selectedPhoto) { _, newItem in
                guard let newItem else { return }
                Task { await uploadPhoto(newItem) }
            }
            .onAppear {
                editFirstName = user?.firstName ?? ""
                editLastName = user?.lastName ?? ""
            }
        }
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        VStack(spacing: 10) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let url = user?.imageUrl, let imageURL = URL(string: url), user?.hasImage == true {
                            AsyncImage(url: imageURL) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                avatarPlaceholder
                            }
                        } else {
                            avatarPlaceholder
                        }
                    }
                    .frame(width: 90, height: 90)
                    .clipShape(Circle())
                    .overlay {
                        if isUploadingPhoto {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 90, height: 90)
                            ProgressView()
                        }
                    }

                    // Camera badge
                    Image(systemName: "camera.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(WeepColor.accent))
                        .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                }
            }
            .disabled(isUploadingPhoto)

            Text(displayName)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color(.label))

            Text("Edit photo")
                .font(.system(size: 14))
                .foregroundStyle(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle().fill(Color(.systemGray5))
            Text(initials)
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(.secondaryLabel))
        }
    }

    // MARK: - Personal Info

    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionHeader("Personal Information")
                Spacer()
                if isEditingName {
                    Button {
                        Task { await saveName() }
                    } label: {
                        if isSavingName {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Save")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(WeepColor.accent)
                        }
                    }
                    .disabled(isSavingName)
                    .padding(.trailing, 4)
                } else {
                    Button {
                        editFirstName = user?.firstName ?? ""
                        editLastName = user?.lastName ?? ""
                        nameError = nil
                        withAnimation(.easeInOut(duration: 0.2)) { isEditingName = true }
                    } label: {
                        Text("Edit")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                    .padding(.trailing, 4)
                }
            }

            VStack(spacing: 0) {
                if isEditingName {
                    editableNameRow(label: "First Name", text: $editFirstName)
                    Divider()
                    editableNameRow(label: "Last Name", text: $editLastName)
                } else {
                    detailRow(label: "First Name", value: user?.firstName ?? "—")
                    Divider()
                    detailRow(label: "Last Name", value: user?.lastName ?? "—")
                }

                Divider()

                if let email = user?.emailAddresses.first?.emailAddress {
                    detailRow(label: "Email", value: email)
                    Divider()
                }
                if let phone = user?.phoneNumbers.first?.phoneNumber {
                    detailRow(label: "Phone", value: phone)
                    Divider()
                }
                detailRow(label: "Member since", value: memberSince)
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
            )

            if let nameError {
                Text(nameError)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(.systemRed))
                    .padding(.leading, 4)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isEditingName)
    }

    // MARK: - Connected Accounts

    private var connectedAccountsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Connected Accounts")

            VStack(spacing: 0) {
                if let accounts = user?.externalAccounts, !accounts.isEmpty {
                    ForEach(Array(accounts.enumerated()), id: \.offset) { index, account in
                        HStack(spacing: 14) {
                            providerLogo(account.provider)
                                .frame(width: 30, height: 30)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(providerDisplayName(account.provider))
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color(.label))
                                Text(account.emailAddress)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(.secondaryLabel))
                            }

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color(.systemGreen))
                                .font(.system(size: 18))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        if index < accounts.count - 1 {
                            Divider()
                        }
                    }
                } else {
                    HStack {
                        Text("No connected accounts")
                            .font(.system(size: 15))
                            .foregroundStyle(Color(.secondaryLabel))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
            )
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color(.tertiaryLabel))
            .textCase(.uppercase)
            .padding(.leading, 4)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(Color(.label))
            Spacer()
            Text(value)
                .font(.system(size: 15))
                .foregroundStyle(Color(.secondaryLabel))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private func editableNameRow(label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(Color(.label))
            Spacer()
            TextField(label, text: text)
                .font(.system(size: 15))
                .foregroundStyle(Color(.label))
                .multilineTextAlignment(.trailing)
                .textContentType(label == "First Name" ? .givenName : .familyName)
                .submitLabel(.done)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    @ViewBuilder
    private func providerLogo(_ provider: String) -> some View {
        switch provider.lowercased() {
        case "google":
            Image("GoogleLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22, height: 22)
        case "apple":
            Image(systemName: "apple.logo")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color(.label))
        default:
            Image(systemName: "link.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color(.systemBlue))
        }
    }

    private func providerDisplayName(_ provider: String) -> String {
        switch provider.lowercased() {
        case "google": return "Google"
        case "apple": return "Apple"
        case "github": return "GitHub"
        default: return provider.capitalized
        }
    }

    private var displayName: String {
        let first = user?.firstName ?? ""
        let last = user?.lastName ?? ""
        let full = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
        return full.isEmpty ? (user?.username ?? "User") : full
    }

    private var initials: String {
        let first = user?.firstName?.prefix(1) ?? ""
        let last = user?.lastName?.prefix(1) ?? ""
        let combined = "\(first)\(last)"
        return combined.isEmpty ? "?" : combined.uppercased()
    }

    private var memberSince: String {
        guard let date = user?.createdAt else { return "—" }
        return date.formatted(.dateTime.month(.wide).year())
    }

    // MARK: - Actions

    private func saveName() async {
        isSavingName = true
        nameError = nil

        let first = editFirstName.trimmingCharacters(in: .whitespaces)
        let last = editLastName.trimmingCharacters(in: .whitespaces)

        do {
            try await user?.update(.init(
                firstName: first.isEmpty ? nil : first,
                lastName: last.isEmpty ? nil : last
            ))
            withAnimation(.easeInOut(duration: 0.2)) { isEditingName = false }
        } catch {
            nameError = "Failed to update name. Please try again."
        }

        isSavingName = false
    }

    private func uploadPhoto(_ item: PhotosPickerItem) async {
        isUploadingPhoto = true
        defer { isUploadingPhoto = false }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data),
              let jpegData = uiImage.jpegData(compressionQuality: 0.8) else { return }

        do {
            try await user?.setProfileImage(imageData: jpegData)
        } catch {
            // Silently fail — user will see the old avatar
        }
    }
}
