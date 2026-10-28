import SwiftUI

/// "Grown-ups: hold for 3 seconds", with a ring that fills while held (DESIGN.md). No maths puzzles: they exclude
/// some parents. VoiceOver and Switch Control users double-tap and hold.
struct GrownUpGateButton: View {
    let action: () -> Void

    @State private var isHolding = false

    var body: some View {
        HStack(spacing: AppSpace.xs) {
            ZStack {
                Circle().stroke(AppColor.hairline, lineWidth: 4)
                Circle()
                    .trim(from: 0, to: isHolding ? 1 : 0)
                    .stroke(AppColor.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: "lock.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColor.inkMuted)
            }
            .frame(width: 36, height: 36)
            Text("Grown-ups: hold for 3 seconds")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppColor.inkMuted)
        }
        .padding(.horizontal, AppSpace.sm)
        .frame(minHeight: 52)
        .background(AppColor.surface, in: Capsule())
        .overlay(Capsule().strokeBorder(AppColor.hairline))
        .contentShape(Capsule())
        .onLongPressGesture(minimumDuration: 3, maximumDistance: 30) {
            isHolding = false
            action()
        } onPressingChanged: { pressing in
            withAnimation(pressing ? .linear(duration: 3) : .easeOut(duration: 0.2)) {
                isHolding = pressing
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Grown-up mode"))
        .accessibilityHint(Text("Double-tap and hold for 3 seconds to open"))
        .accessibilityAddTraits(.isButton)
    }
}
