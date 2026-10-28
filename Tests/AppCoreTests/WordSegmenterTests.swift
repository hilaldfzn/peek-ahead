import Testing

@testable import AppCore

@Suite("Word segmentation for narration highlight")
struct WordSegmenterTests {
    @Test func splitsOnSpacesAndPunctuation() {
        let words = WordSegmenter.words(in: "The dentist has a big chair.")
        #expect(words.map(\.text) == ["The", "dentist", "has", "a", "big", "chair"])
    }

    @Test func keepsApostrophesInsideWords() {
        let words = WordSegmenter.words(in: "We go to Grandma\u{2019}s house. It's Lebaran!")
        #expect(words.map(\.text) == ["We", "go", "to", "Grandma\u{2019}s", "house", "It's", "Lebaran"])
    }

    @Test func keepsIndonesianReduplicationAsOneWord() {
        let words = WordSegmenter.words(in: "Kadang-kadang kita menunggu lama.")
        #expect(words.map(\.text) == ["Kadang-kadang", "kita", "menunggu", "lama"])
    }

    @Test func dropsTrailingAndDoubledJoiners() {
        let words = WordSegmenter.words(in: "Wait -- then go- home")
        #expect(words.map(\.text) == ["Wait", "then", "go", "home"])
    }

    @Test func reportsUTF16RangesThatMatchTheSentence() throws {
        let sentence = "Pip \u{1F916} waves at Rafi."
        let words = WordSegmenter.words(in: sentence)
        #expect(words.map(\.text) == ["Pip", "waves", "at", "Rafi"])
        for word in words {
            let range = try #require(word.stringRange(in: sentence))
            #expect(String(sentence[range]) == word.text)
        }
    }

    @Test func findsTheWordASpeechRangeOverlaps() {
        let sentence = "The dentist has a big chair."
        let words = WordSegmenter.words(in: sentence)
        // "big" starts at UTF-16 offset 18.
        #expect(words.indexOfWord(overlapping: 18..<21) == 4)
        #expect(words.indexOfWord(overlapping: 3..<4) == nil)  // the space after "The"
    }

    @Test func returnsNoRangeForOffsetsOutsideTheSentence() {
        let word = SpokenWord(text: "far", utf16Range: 40..<43)
        #expect(word.stringRange(in: "short") == nil)
    }

    @Test func handlesEmptyText() {
        #expect(WordSegmenter.words(in: "").isEmpty)
        #expect(WordSegmenter.words(in: "  ...  ").isEmpty)
    }
}
