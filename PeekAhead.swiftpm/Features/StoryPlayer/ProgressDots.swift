import SwiftUI

/// Where the child is in the story. VoiceOver reads it as "Page 2 of 4".
struct ProgressDots: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: AppSpace.xs) {
            ForEach(0..<total, id: \.self) { index in
                let isCurrent = index == current
                Circle()
                    .fill(isCurrent ? AppColor.primary : AppColor.hairline)
                    .frame(width: isCurrent ? 14 : 10, height: isCurrent ? 14 : 10)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Page \(current + 1) of \(total)"))
    }
}
