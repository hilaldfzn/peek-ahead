import SwiftUI

/// The large child-mode button: 88 pt tall, rounded, with a clear border on the secondary kind.
struct ChildButtonStyle: ButtonStyle {
    enum Kind {
        case primary
        case secondary
    }

    var kind: Kind

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
        configuration.label
            .font(AppFont.buttonChild)
            .foregroundStyle(kind == .primary ? AppColor.onPrimary : AppColor.ink)
            .padding(.horizontal, AppSpace.xl)
            .frame(maxWidth: .infinity, minHeight: AppSize.childButtonHeight)
            .background(kind == .primary ? AppColor.primary : AppColor.surface, in: shape)
            .overlay {
                if kind == .secondary {
                    shape.strokeBorder(AppColor.line, lineWidth: AppSize.border)
                }
            }
            .contentShape(shape)
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

extension ButtonStyle where Self == ChildButtonStyle {
    static var childPrimary: ChildButtonStyle { ChildButtonStyle(kind: .primary) }
    static var childSecondary: ChildButtonStyle { ChildButtonStyle(kind: .secondary) }
}
