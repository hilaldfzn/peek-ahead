import SwiftUI

/// A rule-check chip under a sentence (DESIGN.md): leaf "Short and clear", coral "worth changing", sky "worth a
/// second look". Each chip has an icon and words, so colour is never the only signal.
struct RuleChip: View {
    let finding: RuleFinding?

    var body: some View {
        Label {
            Text(message)
        } icon: {
            Image(systemName: symbol)
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(ink)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(tint, in: Capsule())
    }

    private var message: String {
        guard let finding else { return String(localized: "Short and clear") }
        let match = finding.match ?? ""
        switch finding.rule {
        case .directive: return String(localized: "Says \u{201C}\(match)\u{201D}. Try \u{201C}I can\u{2026}\u{201D}")
        case .absolute:
            return String(
                localized: "Says \u{201C}\(match)\u{201D}. Try \u{201C}usually\u{201D} or \u{201C}might\u{201D}")
        case .length: return String(localized: "Long sentence. Split it into two pages")
        case .idiom: return String(localized: "\u{201C}\(match)\u{201D} is an idiom. Say it literally")
        case .ratio: return String(localized: "Add describing pages: two for each \u{201C}I can\u{201D} page")
        case .ending: return String(localized: "End with something good and true")
        }
    }

    private var symbol: String {
        switch finding?.severity {
        case nil: "checkmark.circle.fill"
        case .change: "exclamationmark.circle.fill"
        case .consider: "lightbulb.fill"
        }
    }

    private var ink: Color {
        switch finding?.severity {
        case nil: AppColor.leaf
        case .change: AppColor.coral
        case .consider: AppColor.sky
        }
    }

    private var tint: Color {
        switch finding?.severity {
        case nil: AppColor.leafTint
        case .change: AppColor.coralTint
        case .consider: AppColor.skyTint
        }
    }
}

/// Marks a story that was drafted rather than written by the grown-up (DESIGN.md "AI badge").
struct DraftBadge: View {
    let source: DraftSource

    var body: some View {
        Label {
            switch source {
            case .onDeviceModel: Text("Draft written on this iPad. Please check every sentence.")
            case .template: Text("Draft from a template. Please check every sentence.")
            }
        } icon: {
            Image(systemName: source == .onDeviceModel ? "cpu" : "doc.text")
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(AppColor.sky)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(AppColor.skyTint, in: Capsule())
    }
}
