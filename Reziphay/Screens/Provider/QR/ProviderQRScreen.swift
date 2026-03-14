import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

// MARK: - ViewModel

@Observable
@MainActor
final class ProviderQRViewModel {
    var userId: String = ""
    var userName: String = ""
    var isLoading: Bool = false
    var qrImage: UIImage?

    func load(apiClient: APIClient, currentUser: User?) async {
        if let user = currentUser {
            userId = user.id
            userName = user.fullName
            generateQR()
            return
        }

        isLoading = true
        defer { isLoading = false }
        do {
            let user: User = try await apiClient.get("/auth/me")
            userId = user.id
            userName = user.fullName
            generateQR()
        } catch { }
    }

    private func generateQR() {
        let content = "reziphay://provider/\(userId)"
        qrImage = generateQRCodeImage(from: content)
    }

    private func generateQRCodeImage(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }

        let scale: CGFloat = 10
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledImage = outputImage.transformed(by: transform)

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    var qrContent: String {
        "reziphay://provider/\(userId)"
    }
}

// MARK: - Screen

struct ProviderQRScreen: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = ProviderQRViewModel()
    @State private var showShareSheet = false

    var body: some View {
        VStack(spacing: 0) {
            RZTopBar(title: "My QR Code") {
                RZIconButton(icon: "chevron.left") { dismiss() }
            } trailing: {
                RZIconButton(icon: "square.and.arrow.up") {
                    showShareSheet = true
                }
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: RZSpacing.lg) {
                    if viewModel.isLoading {
                        RZLoadingIndicator()
                            .frame(width: 280, height: 280)
                    } else {
                        qrCard
                    }

                    providerInfo

                    instructionNote

                    RZButton(
                        title: "Share QR Code",
                        variant: .primary,
                        isFullWidth: true
                    ) {
                        showShareSheet = true
                    }
                    .padding(.horizontal, RZSpacing.screenHorizontal)

                    manualCompletionNote

                    Spacer(minLength: RZSpacing.xl)
                }
                .padding(.top, RZSpacing.lg)
            }
        }
        .background(Color.rzBackground)
        .navigationBarHidden(true)
        .sheet(isPresented: $showShareSheet) {
            if let image = viewModel.qrImage {
                ShareSheet(items: [image, viewModel.qrContent])
            }
        }
        .task {
            await viewModel.load(
                apiClient: appState.apiClient,
                currentUser: appState.authManager.currentUser
            )
        }
    }

    // MARK: - QR Card

    private var qrCard: some View {
        VStack(spacing: RZSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: RZRadius.card)
                    .fill(Color.white)
                    .frame(width: 280, height: 280)
                    .rzShadow(RZShadow.sm)

                if let image = viewModel.qrImage {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 240, height: 240)
                } else {
                    VStack(spacing: RZSpacing.xs) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 60))
                            .foregroundStyle(.rzTextTertiary)
                        Text("Loading QR...")
                            .font(.rzBodySmall)
                            .foregroundStyle(.rzTextTertiary)
                    }
                }
            }
        }
    }

    // MARK: - Provider Info

    private var providerInfo: some View {
        VStack(spacing: RZSpacing.xxxs) {
            Text(viewModel.userName)
                .font(.rzH3)
                .fontWeight(.bold)
                .foregroundStyle(.rzTextPrimary)
            Text("Service Provider")
                .font(.rzBody)
                .foregroundStyle(.rzTextSecondary)
        }
    }

    // MARK: - Instruction Note

    private var instructionNote: some View {
        HStack(alignment: .top, spacing: RZSpacing.xs) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(.rzPrimary)
            Text("This QR is used by customers to complete their reservations. Ask customers to scan this when they arrive.")
                .font(.rzBodySmall)
                .foregroundStyle(.rzTextSecondary)
                .multilineTextAlignment(.leading)
        }
        .padding(RZSpacing.sm)
        .background(Color.rzPrimary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
        .padding(.horizontal, RZSpacing.screenHorizontal)
    }

    // MARK: - Manual Completion Note

    private var manualCompletionNote: some View {
        HStack(alignment: .top, spacing: RZSpacing.xs) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 14))
                .foregroundStyle(.rzTextTertiary)
            Text("Customers can also complete reservations manually without scanning QR if needed.")
                .font(.rzCaption)
                .foregroundStyle(.rzTextTertiary)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, RZSpacing.screenHorizontal)
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
