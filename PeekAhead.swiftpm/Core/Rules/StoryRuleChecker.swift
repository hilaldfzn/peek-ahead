import Foundation

/// Something in a story the grown-up may want to change. The checker advises; the grown-up decides.
struct RuleFinding: Hashable, Sendable {
    enum Rule: String, Sendable, CaseIterable {
        /// Tells the child what not to do ("don't", "never", "jangan").
        case directive
        /// Promises what will happen ("always", "will", "selalu").
        case absolute
        /// A sentence longer than 12 words.
        case length
        /// A figure of speech a literal reader may misread ("piece of cake").
        case idiom
        /// Fewer than two describing or feeling pages for each "I can" page.
        case ratio
        /// The last page is not marked as ending well.
        case ending
    }

    enum Severity: Sendable {
        /// Coral chip: worth changing.
        case change
        /// Sky chip: worth a second look.
        case consider
    }

    let rule: Rule
    /// The page the finding is about, or `nil` for the story as a whole.
    let pageID: String?
    /// The word or phrase that triggered it, if any.
    let match: String?

    var severity: Severity {
        switch rule {
        case .absolute, .ending: .consider
        case .directive, .length, .idiom, .ratio: .change
        }
    }
}

/// Deterministic checks for the story language rules in DESIGN.md, in English and Indonesian.
///
/// Word lists are deliberately short and literal. They catch common slips; they are not a judgement of the text,
/// and the expert reviewer should check the lists themselves.
enum StoryRuleChecker {
    static let maxWordsPerSentence = 12
    static let describingPerICan = 2

    struct Vocabulary: Sendable {
        let directives: [String]
        let absolutes: [String]
        let idioms: [String]
    }

    static let english = Vocabulary(
        directives: ["don't", "do not", "never", "stop", "must", "have to", "can't", "cannot"],
        absolutes: ["always", "will", "won't", "every time"],
        idioms: [
            "piece of cake", "hop in", "cry over spilt milk", "break a leg", "a breeze", "hang in there",
            "in a jiffy", "keep your chin up", "under the weather",
        ]
    )

    static let indonesian = Vocabulary(
        directives: ["jangan", "tidak boleh", "dilarang", "harus", "berhenti"],
        absolutes: ["selalu", "pasti", "akan", "setiap kali", "tidak akan"],
        idioms: ["makan hati", "kepala batu", "buah bibir", "panjang tangan", "naik darah"]
    )

    static func vocabulary(for language: String) -> Vocabulary {
        language.lowercased().hasPrefix("id") ? indonesian : english
    }

    /// Every finding for the story: page findings in page order, then story-level findings.
    static func check(_ story: Story) -> [RuleFinding] {
        let vocabulary = vocabulary(for: story.language)
        var findings = story.pages.flatMap { check($0, vocabulary: vocabulary) }

        let iCan = story.pages.filter { $0.kind == .iCan }.count
        let describing = story.pages.filter { $0.kind == .describes || $0.kind == .feelings }.count
        if iCan > 0, describing < iCan * describingPerICan {
            findings.append(RuleFinding(rule: .ratio, pageID: nil, match: nil))
        }
        if let last = story.pages.last, last.kind != .endsWell {
            findings.append(RuleFinding(rule: .ending, pageID: nil, match: nil))
        }
        return findings
    }

    static func check(_ page: StoryPage, language: String) -> [RuleFinding] {
        check(page, vocabulary: vocabulary(for: language))
    }

    private static func check(_ page: StoryPage, vocabulary: Vocabulary) -> [RuleFinding] {
        let tokens = normalizedWords(page.sentence)
        var findings: [RuleFinding] = []
        for (rule, phrases) in [
            (RuleFinding.Rule.directive, vocabulary.directives), (.absolute, vocabulary.absolutes),
            (.idiom, vocabulary.idioms),
        ] {
            if let match = phrases.first(where: { contains(tokens, phrase: $0) }) {
                findings.append(RuleFinding(rule: rule, pageID: page.id, match: match))
            }
        }
        if sentences(in: page.sentence).contains(where: { WordSegmenter.words(in: $0).count > maxWordsPerSentence }) {
            findings.append(RuleFinding(rule: .length, pageID: page.id, match: nil))
        }
        return findings
    }

    /// Lower-cased words with curly apostrophes made straight, so "Don’t" matches "don't".
    private static func normalizedWords(_ text: String) -> [String] {
        WordSegmenter.words(in: text).map { $0.text.lowercased().replacingOccurrences(of: "\u{2019}", with: "'") }
    }

    private static func contains(_ tokens: [String], phrase: String) -> Bool {
        let parts = normalizedWords(phrase)
        guard !parts.isEmpty, tokens.count >= parts.count else { return false }
        return (0...(tokens.count - parts.count)).contains { Array(tokens[$0..<($0 + parts.count)]) == parts }
    }

    private static func sentences(in text: String) -> [String] {
        text.split(whereSeparator: { ".!?".contains($0) }).map(String.init)
    }
}
