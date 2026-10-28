import SwiftUI

/// The page sentence, with the word being spoken marked in sun yellow (background plus underline, so the cue
/// does not rely on colour alone).
struct HighlightedSentence: View {
    let sentence: String
    let words: [SpokenWord]
    let highlightedIndex: Int?

    var body: some View {
        Text(attributedSentence)
            .font(AppFont.storySentence)
            .lineSpacing(AppFont.storyLineSpacing)
            .foregroundStyle(AppColor.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(Text(sentence))
    }

    private var attributedSentence: AttributedString {
        var text = AttributedString(sentence)
        guard let index = highlightedIndex, words.indices.contains(index),
            let stringRange = words[index].stringRange(in: sentence),
            let range = Range<AttributedString.Index>(stringRange, in: text)
        else {
            return text
        }
        text[range].backgroundColor = AppColor.sunTint
        text[range].underlineStyle = Text.LineStyle(pattern: .solid, color: AppColor.sun)
        return text
    }
}
