import SwiftUI

enum RZToastType {
    case success, error, info

    var icon: String {
        switch self {
        case .success: "checkmark.circle.fill"
        case .error: "exclamationmark.circle.fill"
        case .info: "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: .rzSuccess
        case .error: .rzError
        case .info: .rzPrimary
        }
    }
}

struct RZToast: View {
    let message: String
    let type: RZToastType

    var body: some View {
        HStack(spacing: RZSpacing.xxs) {
            Image(systemName: type.icon)
                .foregroundStyle(type.color)
            Text(message)
                .font(.rzBody)
                .foregroundStyle(.rzTextPrimary)
        }
        .padding(.horizontal, RZSpacing.sm)
        .padding(.vertical, RZSpacing.xs)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: RZRadius.pill))
        .rzShadow(RZShadow.md)
    }
}

struct RZToastModifier: ViewModifier {
    @Binding var toast: ToastData?

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let toast {
                RZToast(message: toast.message, type: toast.type)
                    .padding(.top, RZSpacing.xxl)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        Task {
                            try? await Task.sleep(for: .seconds(3))
                            withAnimation { self.toast = nil }
                        }
                    }
            }
        }
        .animation(.spring(duration: RZDuration.smallTransition), value: toast != nil)
    }
}

struct ToastData: Equatable {
    let message: String
    let type: RZToastType

    static func == (lhs: ToastData, rhs: ToastData) -> Bool {
        lhs.message == rhs.message
    }
}

extension View {
    func rzToast(_ toast: Binding<ToastData?>) -> some View {
        modifier(RZToastModifier(toast: toast))
    }
}
