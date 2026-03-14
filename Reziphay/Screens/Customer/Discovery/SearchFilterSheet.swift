import SwiftUI

struct SearchFilterSheet: View {
    @Bindable var viewModel: SearchViewModel
    @Binding var isPresented: Bool

    @Environment(AppState.self) private var appState

    // Local draft state
    @State private var draftMinRating: Double? = nil
    @State private var draftMaxPriceText: String = ""
    @State private var draftCategoryId: String? = nil
    @State private var draftOnlyAvailable: Bool = false
    @State private var categories: [ServiceCategory] = []
    @State private var isLoadingCategories = false

    private var draftMaxPrice: Double? {
        Double(draftMaxPriceText.filter { $0.isNumber || $0 == "." })
    }

    var body: some View {
        RZBottomSheet(title: "Filters", onDismiss: { isPresented = false }) {
            VStack(spacing: RZSpacing.sectionVertical) {
                // Rating section
                ratingSection

                // Price section
                priceSection

                // Category section
                categorySection

                // Availability toggle
                availabilityToggle

                // Footer buttons
                footerButtons
            }
            .padding(.bottom, RZSpacing.sm)
        }
        .onAppear {
            // Populate drafts from current viewModel state
            draftMinRating = viewModel.minRating
            draftMaxPriceText = viewModel.maxPrice.map { String(format: "%.0f", $0) } ?? ""
            draftCategoryId = viewModel.categoryId
            draftOnlyAvailable = viewModel.onlyAvailable
            loadCategories()
        }
    }

    // MARK: - Rating Section

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            Text("Minimum Rating")
                .font(.rzH4)
                .foregroundStyle(.rzTextPrimary)

            HStack(spacing: RZSpacing.xxs) {
                // "Any" pill
                ratingPill(label: "Any", value: nil)

                ForEach([1.0, 2.0, 3.0, 4.0, 5.0], id: \.self) { rating in
                    ratingPill(label: "\(Int(rating))★", value: rating)
                }
            }
        }
    }

    private func ratingPill(label: String, value: Double?) -> some View {
        let isSelected = draftMinRating == value
        return Button {
            draftMinRating = value
        } label: {
            Text(label)
                .font(.rzLabel)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : .rzTextSecondary)
                .padding(.horizontal, RZSpacing.xs)
                .padding(.vertical, RZSpacing.xxs)
                .background(isSelected ? Color.rzPrimary : Color.rzInputBackground)
                .clipShape(Capsule())
        }
    }

    // MARK: - Price Section

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            Text("Maximum Price")
                .font(.rzH4)
                .foregroundStyle(.rzTextPrimary)

            HStack(spacing: RZSpacing.xs) {
                HStack(spacing: RZSpacing.xxs) {
                    Text("Up to")
                        .font(.rzBody)
                        .foregroundStyle(.rzTextTertiary)
                    TextField("Any", text: $draftMaxPriceText)
                        .font(.rzBody)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    if !draftMaxPriceText.isEmpty {
                        Button { draftMaxPriceText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.rzTextTertiary)
                        }
                    }
                }
                .padding(.horizontal, RZSpacing.xs)
                .frame(height: 40)
                .background(Color.rzInputBackground)
                .clipShape(RoundedRectangle(cornerRadius: RZRadius.input))
            }

            // Quick price chips
            HStack(spacing: RZSpacing.xxs) {
                ForEach(["25", "50", "100", "200"], id: \.self) { price in
                    Button {
                        draftMaxPriceText = price
                    } label: {
                        Text("\(price)")
                            .font(.rzCaption)
                            .foregroundStyle(draftMaxPriceText == price ? .white : .rzTextSecondary)
                            .padding(.horizontal, RZSpacing.xs)
                            .padding(.vertical, RZSpacing.xxxs)
                            .background(draftMaxPriceText == price ? Color.rzPrimary : Color.rzInputBackground)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            Text("Category")
                .font(.rzH4)
                .foregroundStyle(.rzTextPrimary)

            if isLoadingCategories {
                RZSkeletonView(height: 40, radius: RZRadius.input)
            } else if categories.isEmpty {
                Text("No categories available")
                    .font(.rzBodySmall)
                    .foregroundStyle(.rzTextTertiary)
            } else {
                VStack(spacing: 0) {
                    // "All categories" option
                    categoryRow(id: nil, name: "All Categories")
                    Divider().padding(.leading, RZSpacing.xl)

                    ForEach(Array(categories.enumerated()), id: \.element.id) { index, cat in
                        categoryRow(id: cat.id, name: cat.name)
                        if index < categories.count - 1 {
                            Divider().padding(.leading, RZSpacing.xl)
                        }
                    }
                }
                .background(Color.rzSurface)
                .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
                .rzShadow(RZShadow.sm)
            }
        }
    }

    private func categoryRow(id: String?, name: String) -> some View {
        let isSelected = draftCategoryId == id
        return Button {
            draftCategoryId = id
        } label: {
            HStack {
                Text(name)
                    .font(.rzBody)
                    .foregroundStyle(isSelected ? .rzPrimary : .rzTextPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.rzPrimary)
                }
            }
            .padding(.horizontal, RZSpacing.sm)
            .padding(.vertical, RZSpacing.xs)
        }
    }

    // MARK: - Availability Toggle

    private var availabilityToggle: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Available only")
                    .font(.rzBody)
                    .fontWeight(.medium)
                    .foregroundStyle(.rzTextPrimary)
                Text("Show only services available right now")
                    .font(.rzCaption)
                    .foregroundStyle(.rzTextTertiary)
            }
            Spacer()
            Toggle("", isOn: $draftOnlyAvailable)
                .tint(.rzPrimary)
                .labelsHidden()
        }
        .padding(RZSpacing.sm)
        .background(Color.rzSurface)
        .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
        .rzShadow(RZShadow.sm)
    }

    // MARK: - Footer Buttons

    private var footerButtons: some View {
        HStack(spacing: RZSpacing.xs) {
            RZButton(title: "Clear", variant: .ghost, size: .medium) {
                draftMinRating = nil
                draftMaxPriceText = ""
                draftCategoryId = nil
                draftOnlyAvailable = false
                Task {
                    await viewModel.clearFilters(apiClient: appState.apiClient)
                    isPresented = false
                }
            }

            RZButton(title: "Apply Filters", variant: .primary, size: .medium) {
                Task {
                    await viewModel.applyFilters(
                        minRating: draftMinRating,
                        maxPrice: draftMaxPrice,
                        categoryId: draftCategoryId,
                        onlyAvailable: draftOnlyAvailable,
                        apiClient: appState.apiClient
                    )
                    isPresented = false
                }
            }
        }
    }

    // MARK: - Data Loading

    private func loadCategories() {
        isLoadingCategories = true
        Task {
            defer { isLoadingCategories = false }
            do {
                let result: [ServiceCategory] = try await appState.apiClient.get(APIEndpoints.categories)
                categories = result
            } catch {
                // silent fail
            }
        }
    }
}
