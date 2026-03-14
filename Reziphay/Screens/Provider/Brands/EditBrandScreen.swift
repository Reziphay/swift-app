import SwiftUI
import PhotosUI

// MARK: - ViewModel

@Observable
@MainActor
final class EditBrandViewModel {
    var name: String = ""
    var description: String = ""
    var addressText: String = ""
    var isLoading: Bool = false
    var isSubmitting: Bool = false
    var brand: Brand?

    var selectedPhotoItem: PhotosPickerItem?
    var logoImageData: Data?

    func load(brandId: String, apiClient: APIClient) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let b: Brand = try await apiClient.get(APIEndpoints.brand(brandId))
            brand = b
            name = b.name
            description = b.description ?? ""
            addressText = b.primaryAddress?.fullAddress ?? ""
        } catch { }
    }

    func save(brandId: String, apiClient: APIClient) async throws {
        struct PatchBrandBody: Encodable {
            let name: String
            let description: String?
            let address: String?
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let body = PatchBrandBody(
            name: name.trimmingCharacters(in: .whitespaces),
            description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespaces),
            address: addressText.isEmpty ? nil : addressText.trimmingCharacters(in: .whitespaces)
        )

        let updated: Brand = try await apiClient.patch(APIEndpoints.brand(brandId), body: body)
        brand = updated

        if let imageData = logoImageData {
            _ = try? await apiClient.upload(
                APIEndpoints.brandLogo(brandId),
                fileData: imageData,
                fileName: "logo.jpg",
                mimeType: "image/jpeg"
            ) as Brand
        }
    }

    func loadSelectedPhoto() async {
        guard let item = selectedPhotoItem else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            logoImageData = data
        }
    }
}

// MARK: - Screen

struct EditBrandScreen: View {
    let brandId: String

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = EditBrandViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.rzBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                RZTopBar(title: "Edit Brand") {
                    RZIconButton(icon: "chevron.left") { dismiss() }
                }

                if viewModel.isLoading {
                    Spacer()
                    RZLoadingIndicator()
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: RZSpacing.sectionVertical) {
                            logoSection
                            formSection
                        }
                        .padding(.horizontal, RZSpacing.screenHorizontal)
                        .padding(.top, RZSpacing.md)
                        .padding(.bottom, 100)
                    }
                }
            }

            if !viewModel.isLoading {
                VStack(spacing: 0) {
                    Divider()
                    RZButton(
                        title: "Save Changes",
                        variant: .primary,
                        size: .large,
                        isFullWidth: true,
                        isLoading: viewModel.isSubmitting
                    ) {
                        handleSave()
                    }
                    .padding(.horizontal, RZSpacing.screenHorizontal)
                    .padding(.vertical, RZSpacing.sm)
                    .background(Color.rzBackground)
                }
            }
        }
        .navigationBarHidden(true)
        .onChange(of: viewModel.selectedPhotoItem) { _, _ in
            Task { await viewModel.loadSelectedPhoto() }
        }
        .task {
            await viewModel.load(brandId: brandId, apiClient: appState.apiClient)
        }
    }

    // MARK: - Logo Section

    private var logoSection: some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            Text("Brand Logo")
                .font(.rzH4)
                .foregroundStyle(.rzTextPrimary)

            PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                ZStack {
                    RoundedRectangle(cornerRadius: RZRadius.card)
                        .fill(Color.rzSurface)
                        .frame(height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: RZRadius.card)
                                .strokeBorder(Color.rzBorder, style: StrokeStyle(lineWidth: 1, dash: [6]))
                        )

                    if let data = viewModel.logoImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
                    } else if let logoURL = viewModel.brand?.logoURL {
                        AsyncImage(url: logoURL) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
                        } placeholder: {
                            logoPlaceholder
                        }
                    } else {
                        logoPlaceholder
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var logoPlaceholder: some View {
        VStack(spacing: RZSpacing.xxs) {
            Image(systemName: "camera.fill")
                .font(.system(size: 28))
                .foregroundStyle(.rzTextTertiary)
            Text("Tap to change logo")
                .font(.rzBodySmall)
                .foregroundStyle(.rzTextTertiary)
        }
    }

    // MARK: - Form Section

    private var formSection: some View {
        VStack(spacing: RZSpacing.sm) {
            RZTextField(
                title: "Brand Name",
                placeholder: "e.g. Luxe Hair Studio",
                text: $viewModel.name
            )

            RZTextArea(
                title: "Description (optional)",
                placeholder: "Describe your brand, specialties, and what makes you unique...",
                text: $viewModel.description
            )

            RZTextField(
                title: "Address",
                placeholder: "e.g. 123 Main St, New York, NY",
                text: $viewModel.addressText
            )
        }
    }

    // MARK: - Action

    private func handleSave() {
        guard !viewModel.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            appState.showToast("Brand name is required.", type: .error)
            return
        }

        Task {
            do {
                try await viewModel.save(brandId: brandId, apiClient: appState.apiClient)
                appState.showToast("Brand updated successfully.", type: .success)
                dismiss()
            } catch {
                appState.showToast("Failed to save changes.", type: .error)
            }
        }
    }
}

// MARK: - BrandAddress extension

private extension BrandAddress {
}
