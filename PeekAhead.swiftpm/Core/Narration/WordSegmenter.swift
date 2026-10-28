import Foundation

/// A word inside a sentence, located by UTF-16 offsets.
///
/// UTF-16 offsets are what `AVSpeechSynthesizer` reports while it speaks, so a reported range can be matched
/// to a word without converting between index types on every callback.
struct SpokenWord: Hashable, Sendable {
    let text: String
    let utf16Range: Range<Int>

    /// The word's range as `String.Index` values in `sentence`, or `nil` if the offsets don't fit the sentence.
    func stringRange(in sentence: String) -> Range<String.Index>? {
        let utf16 = sentence.utf16
        guard utf16Range.lowerBound >= 0, utf16Range.upperBound <= utf16.count else { return nil }
        let lower = String.Index(utf16Offset: utf16Range.lowerBound, in: sentence)
        let upper = String.Index(utf16Offset: utf16Range.upperBound, in: sentence)
        return lower..<upper
    }
}

/// Splits a sentence into words for narration highlighting.
///
/// Letters and digits form words. An apostrophe or hyphen joins two words when it sits between letters, so
/// "Grandma’s" and the Indonesian reduplication "kadang-kadang" each count as one word.
enum WordSegmenter {
    private static let joiners: Set<Character> = ["'", "\u{2019}", "-", "\u{2010}"]

    static func words(in sentence: String) -> [SpokenWord] {
        var words: [SpokenWord] = []
        var current = ""
        var start = 0
        var offset = 0
        var pendingJoiner: Character?

        func flush() {
            if !current.isEmpty {
                words.append(SpokenWord(text: current, utf16Range: start..<(start + current.utf16.count)))
            }
            current = ""
            pendingJoiner = nil
        }

        for character in sentence {
            if character.isLetter || character.isNumber {
                if current.isEmpty {
                    start = offset
                } else if let joiner = pendingJoiner {
                    current.append(joiner)
                }
                pendingJoiner = nil
                current.append(character)
            } else if joiners.contains(character), !current.isEmpty, pendingJoiner == nil {
                pendingJoiner = character
            } else {
                flush()
            }
            offset += character.utf16.count
        }
        flush()
        return words
    }
}

extension Array where Element == SpokenWord {
    /// The index of the word that overlaps `range`, such as the range a speech synthesizer is about to speak.
    func indexOfWord(overlapping range: Range<Int>) -> Int? {
        firstIndex { $0.utf16Range.overlaps(range) }
    }
}
