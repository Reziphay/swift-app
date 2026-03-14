import SwiftUI

// MARK: - ViewModel

@Observable
@MainActor
final class BrandJoinRequestsViewModel {
    var requests: [BrandJoinRequest] = []
    var isLoading: Bool = false
    var actingOnId: String? = nil

    func load(brandId: String, apiClient: APIClient) async {
        isLoading = true
        defer { isLoading = false }
        do {
            requests = try await apiClient.get(APIEndpoints.brandJoinRequests(brandId))
        } catch { }
    }

    func accept(brandId: String, requestId: String, apiClient: APIClient) async throws {
        actingOnId = requestId
        defer { actingOnId = nil }
        struct EmptyBody: Encodable {}
        try await apiClient.postVoid(
            APIEndpoints.brandJoinRequestAction(brandId, requestId, "accept"),
            body: EmptyBody()
        )
        requests.removeAll { $0.id == requestId }
    }

    func reject(brandId: String, requestId: String, apiClient: APIClient) async throws {
        actingOnId = requestId
        defer { actingOnId = nil }
        struct EmptyBody: Encodable {}
        try await apiClient.postVoid(
            APIEndpoints.brandJoinRequestAction(brandId, requestId, "reject"),
            body: EmptyBody()
        )
        requests.removeAll { $0.id == requestId }
    }
}

// MARK: - Screen

struct BrandJoinRequestsScreen: View {
    let brandId: String

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = BrandJoinRequestsViewModel()
    @State private var confirmAcceptId: String? = nil
    @State private var confirmRejectId: String? = nil
    @State private var showAcceptConfirm: Bool = false
    @State private var showRejectConfirm: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            RZTopBar(title: "Join Requests") {
                RZIconButton(icon: "chevron.left") { dismiss() }
            }

            if viewModel.isLoading {
                skeletonList
            } else if viewModel.requests.isEmpty {
                emptyState
            } else {
                requestList
            }
        }
        .background(Color.rzBackground)
        .navigationBarHidden(true)
        .confirmationDialog(
            "Accept this member?",
            isPresented: $showAcceptConfirm,
            titleVisibility: .visible
        ) {
            Button("Accept", role: .none) {
                guard let id = confirmAcceptId else { return }
                Task {
                    do {
                        try await viewModel.accept(brandId: brandId, requestId: id, apiClient: appState.apiClient)
                        appState.showToast("Member accepted.", type: .success)
                    } catch {
                        appState.showToast("Failed to accept request.", type: .error)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The user will be added as a member of this brand.")
        }
        .confirmationDialog(
            "Reject this request?",
            isPresented: $showRejectConfirm,
            titleVisibility: .visible
        ) {
            Button("Reject", role: .destructive) {
                guard let id = confirmRejectId else { return }
                Task {
                    do {
                        try await viewModel.reject(brandId: brandId, requestId: id, apiClient: appState.apiClient)
                        appState.showToast("Request rejected.", type: .info)
                    } catch {
                        appState.showToast("Failed to reject request.", type: .error)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The join request will be declined.")
        }
        .task {
            await viewModel.load(brandId: brandId, apiClient: appState.apiClient)
        }
        .refreshable {
            await viewModel.load(brandId: brandId, apiClient: appState.apiClient)
        }
    }

    // MARK: - Request List

    private var requestList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: RZSpacing.xs) {
                ForEach(viewModel.requests) { request in
                    requestRow(request: request)
                        .padding(.horizontal, RZSpacing.screenHorizontal)
                }
            }
            .padding(.top, RZSpacing.sm)
            .padding(.bottom, RZSpacing.xl)
        }
    }

    private func requestRow(request: BrandJoinRequest) -> some View {
        let isActing = viewModel.actingOnId == request.id

        return RZCard {
            VStack(alignment: .leading, spacing: RZSpacing.xs) {
                HStack(alignment: .top, spacing: RZSpacing.xs) {
                    RZAvatarView(
                        name: request.requester?.fullName ?? "?",
                        size: 40
                    )

                    VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                        Text(request.requester?.fullName ?? "Unknown User")
                            .font(.rzBodyLarge)
                            .fontWeight(.semibold)
                            .foregroundStyle(.rzTextPrimary)

                        if let email = request.requester?.email {
                            Text(email)
                                .font(.rzBodySmall)
                                .foregroundStyle(.rzTextSecondary)
                        }

                        Text(formattedDate(request.createdAt))
                            .font(.rzCaption)
                            .foregroundStyle(.rzTextTertiary)
                    }

                    Spacer()

                    RZStatusPill(
                        text: request.status.rawValue.capitalized,
                        color: statusColor(request.status)
                    )
                }

                if let message = request.message, !message.isEmpty {
                    Text(message)
                        .font(.rzBodySmall)
                        .foregroundStyle(.rzTextSecondary)
                        .padding(.top, RZSpacing.xxxs)
                }

                if request.status == .pending {
                    HStack(spacing: RZSpacing.xxs) {
                        RZButton(
                            title: "Accept",
                            variant: .primary,
                            size: .small,
                            isFullWidth: true,
                            isLoading: isActing
                        ) {
                            confirmAcceptId = request.id
                            showAcceptConfirm = true
                        }
                        RZButton(
                            title: "Reject",
                            variant: .ghost,
                            size: .small,
                            isFullWidth: true,
                            isLoading: isActing
                        ) {
                            confirmRejectId = request.id
                            showRejectConfirm = true
                        }
                    }
                }
            }
        }
    }

    private func statusColor(_ status: BrandJoinRequestStatus) -> Color {
        switch status {
        case .pending: return .rzWarning
        case .accepted: return .rzSuccess
        case .rejected: return .rzError
        }
    }

    private func formattedDate(_ dateString: String) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: dateString) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return dateString
    }

    // MARK: - Empty State

    private var emptyState: some View {
        RZEmptyState(
            icon: "person.badge.clock",
            title: "No join requests",
            subtitle: "New membership requests will appear here."
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Skeleton

    private var skeletonList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RZSpacing.xs) {
                ForEach(0..<4, id: \.self) { _ in
                    RZSkeletonView(height: 100, radius: RZRadius.card)
                        .padding(.horizontal, RZSpacing.screenHorizontal)
                }
            }
            .padding(.top, RZSpacing.sm)
        }
        .allowsHitTesting(false)
    }
}
