import SwiftUI
import PhotosUI

// MARK: - ViewModel

@Observable
@MainActor
final class CreateBrandViewModel {
    var name: String = ""
    var description: String = ""
    var addressText: String = ""
    var isSubmitting: Bool = false

    var selectedPhotoItem: PhotosPickerItem?
    var logoImageData: Data?

    func submit(apiClient: APIClient) async throws -> Brand {
        struct CreateBrandBody: Encodable {
            let name: String
            let description: String?
            let address: String?
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let body = CreateBrandBody(
            name: name.trimmingCharacters(in: .whitespaces),
            description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespaces),
            address: addressText.isEmpty ? nil : addressText.trimmingCharacters(in: .whitespaces)
        )

        let brand: Brand = try await apiClient.post(APIEndpoints.brands, body: body)

        if let imageData = logoImageData {
            _ = try? await apiClient.upload(
                APIEndpoints.brandLogo(brand.id),
                fileData: imageData,
                fileName: "logo.jpg",
                mimeType: "image/jpeg"
            ) as Brand
        }

        return brand
    }

    func loadSelectedPhoto() async {
        guard let item = selectedPhotoItem else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            logoImageData = data
        }
    }
}

// MARK: - Screen

struct CreateBrandScreen: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = CreateBrandViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.rzBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                RZTopBar(title: "Create Brand") {
                    RZIconButton(icon: "chevron.left") { dismiss() }
                }

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

            VStack(spacing: 0) {
                Divider()
                RZButton(
                    title: "Create Brand",
                    variant: .primary,
                    size: .large,
                    isFullWidth: true,
                    isLoading: viewModel.isSubmitting
                ) {
                    handleCreate()
                }
                .padding(.horizontal, RZSpacing.screenHorizontal)
                .padding(.vertical, RZSpacing.sm)
                .background(Color.rzBackground)
            }
        }
        .navigationBarHidden(true)
        .onChange(of: viewModel.selectedPhotoItem) { _, _ in
            Task { await viewModel.loadSelectedPhoto() }
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
                    } else {
                        VStack(spacing: RZSpacing.xxs) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.rzTextTertiary)
                            Text("Tap to upload logo")
                                .font(.rzBodySmall)
                                .foregroundStyle(.rzTextTertiary)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
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

    private func handleCreate() {
        guard !viewModel.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            appState.showToast("Brand name is required.", type: .error)
            return
        }

        Task {
            do {
                let brand = try await viewModel.submit(apiClient: appState.apiClient)
                appState.showToast("Brand created successfully!", type: .success)
                appState.router.push(.brandManage(id: brand.id), forRole: .uso)
            } catch {
                appState.showToast("Failed to create brand.", type: .error)
            }
        }
    }
}
