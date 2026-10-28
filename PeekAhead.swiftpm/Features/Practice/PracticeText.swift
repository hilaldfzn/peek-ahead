import SwiftUI

extension PracticeActivity {
    var title: LocalizedStringKey {
        switch self {
        case .orderSteps: "Put the steps in order"
        case .soundPreview: "Hear it quietly first"
        case .calmTools: "Pick my calm tools"
        }
    }

    var symbol: String {
        switch self {
        case .orderSteps: "arrow.left.arrow.right"
        case .soundPreview: "ear"
        case .calmTools: "heart"
        }
    }
}

extension CalmTool {
    var title: LocalizedStringKey {
        switch self {
        case .headphones: "Headphones"
        case .sunglasses: "Sunglasses"
        case .squishy: "Squishy toy"
        case .breathe: "Breathe"
        case .quietCorner: "Quiet corner"
        case .breakCard: "Break card"
        case .askForHelp: "Ask for help"
        case .holdHand: "Hold a hand"
        }
    }
}

/// Title, one line of instruction, the activity, and a bottom row of buttons: the same layout for every
/// practice screen, so controls never move (DESIGN.md).
struct PracticeScaffold<Content: View, Buttons: View>: View {
    let title: LocalizedStringKey
    let instruction: Text
    @ViewBuilder let content: Content
    @ViewBuilder let buttons: Buttons

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpace.lg) {
            VStack(alignment: .leading, spacing: AppSpace.xs) {
                Text(title)
                    .font(AppFont.title)
                    .foregroundStyle(AppColor.ink)
                    .accessibilityAddTraits(.isHeader)
                instruction
                    .font(AppFont.labelChild)
                    .foregroundStyle(AppColor.inkMuted)
            }
            ScrollView {
                content
                    .padding(.vertical, AppSpace.xs)
            }
            HStack(spacing: AppSpace.md) {
                buttons
            }
        }
        .padding(AppSpace.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColor.paper)
    }
}
