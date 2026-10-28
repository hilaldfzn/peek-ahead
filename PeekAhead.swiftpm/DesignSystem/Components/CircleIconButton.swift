import SwiftUI

/// A round icon button with its word underneath, used for Home and Read in the top bar.
/// The word is always shown: children should never have to guess what an icon means.
struct CircleIconButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpace.xxs) {
                Image(systemName: systemImage)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(AppColor.primary)
                    .frame(width: AppSize.iconButton, height: AppSize.iconButton)
                    .background(AppColor.surface, in: Circle())
                    .overlay(Circle().strokeBorder(AppColor.line, lineWidth: AppSize.border))
                Text(title)
                    .font(AppFont.iconLabel)
                    .foregroundStyle(AppColor.ink)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }
}
