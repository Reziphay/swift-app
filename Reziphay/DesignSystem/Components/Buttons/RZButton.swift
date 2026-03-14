import SwiftUI

enum RZButtonVariant {
    case primary, secondary, ghost, destructive
}

enum RZButtonSize {
    case small, medium, large

    var height: CGFloat {
        switch self {
        case .small: 36
        case .medium: 44
        case .large: 52
        }
    }

    var font: Font {
        switch self {
        case .small: .rzLabel
        case .medium: .rzBody
        case .large: .rzBodyLarge
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small: RZSpacing.sm
        case .medium: RZSpacing.md
        case .large: RZSpacing.lg
        }
    }
}

struct RZButton: View {
    let title: String
    var variant: RZButtonVariant = .primary
    var size: RZButtonSize = .large
    var isFullWidth: Bool = true
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: RZSpacing.xxs) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                        .scaleEffect(0.8)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(size.font)
                    }
                    Text(title)
                        .font(size.font.weight(.semibold))
                }
            }
            .frame(height: size.height)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.horizontal, size.horizontalPadding)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: RZRadius.button))
            .overlay {
                if variant == .secondary || variant == .ghost {
                    RoundedRectangle(cornerRadius: RZRadius.button)
                        .strokeBorder(borderColor, lineWidth: variant == .ghost ? 0 : 1)
                }
            }
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1)
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary: .white
        case .secondary: .rzPrimary
        case .ghost: .rzTextPrimary
        case .destructive: .white
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary: .rzPrimary
        case .secondary: .rzPrimary.opacity(0.08)
        case .ghost: .clear
        case .destructive: .rzError
        }
    }

    private var borderColor: Color {
        switch variant {
        case .secondary: .rzPrimary.opacity(0.2)
        default: .clear
        }
    }
}

struct RZIconButton: View {
    let icon: String
    var size: CGFloat = 44
    var color: Color = .rzTextPrimary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
                .frame(width: size, height: size)
                .contentShape(Rectangle())
        }
    }
}
