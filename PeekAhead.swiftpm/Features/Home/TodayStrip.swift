import SwiftUI

/// The day's Now / Next strip (DESIGN.md): done steps fold to the left with a check, "Now" is bigger with a
/// primary border, and "Next" sits beside it. Chosen calm tools are shown underneath as a reminder.
struct TodayStrip: View {
    let plan: DayPlan?
    let calmTools: [CalmTool]
    let onDidIt: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpace.md) {
            Text("Today")
                .font(AppFont.title)
                .foregroundStyle(AppColor.ink)
                .accessibilityAddTraits(.isHeader)
            if let plan {
                if plan.isFinished {
                    Text("All done for today!")
                        .font(AppFont.labelChild)
                        .foregroundStyle(AppColor.leaf)
                } else {
                    ScrollView(.horizontal) {
                        HStack(alignment: .bottom, spacing: AppSpace.md) {
                            ForEach(Array(plan.steps.enumerated()), id: \.element.id) { index, step in
                                StepCard(step: step, state: plan.state(of: index))
                            }
                        }
                        .padding(.vertical, AppSpace.xxs)
                    }
                    Button("I did it", action: onDidIt)
                        .buttonStyle(.childSecondary)
                        .frame(maxWidth: 320)
                }
            }
            if !calmTools.isEmpty {
                HStack(spacing: AppSpace.md) {
                    Text("My calm tools:")
                        .font(AppFont.labelChild)
                        .foregroundStyle(AppColor.ink)
                    ForEach(calmTools) { tool in
                        BundleImage(name: tool.imageName)
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                            .accessibilityLabel(Text(tool.title))
                    }
                }
            }
        }
    }
}

private struct StepCard: View {
    let step: PracticeStep
    let state: DayPlan.StepState

    var body: some View {
        let isNow = state == .now
        let shape = RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
        VStack(alignment: .leading, spacing: AppSpace.xs) {
            Text(label)
                .font(AppFont.iconLabel)
                .foregroundStyle(state == .done ? AppColor.leaf : AppColor.inkMuted)
            BundleImage(name: step.pictogram.imageName)
                .scaledToFit()
                .frame(width: isNow ? 96 : 64, height: isNow ? 96 : 64)
            Text(verbatim: step.label)
                .font(AppFont.labelChild)
                .foregroundStyle(AppColor.ink)
                .lineLimit(2)
        }
        .padding(AppSpace.md)
        .frame(width: isNow ? 220 : 160, alignment: .leading)
        .background(state == .done ? AppColor.leafTint : AppColor.surface, in: shape)
        .overlay(shape.strokeBorder(isNow ? AppColor.primary : AppColor.line, lineWidth: isNow ? 5 : AppSize.border))
        .accessibilityElement(children: .combine)
    }

    private var label: LocalizedStringKey {
        switch state {
        case .done: "Done"
        case .now: "Now"
        case .next: "Next"
        }
    }
}
