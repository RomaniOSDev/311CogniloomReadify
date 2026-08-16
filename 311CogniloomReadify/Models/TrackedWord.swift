import Foundation

/// One close-reading card: a sentence from a book, the tapped word, and the reader's gloss.
struct PassageCard: Identifiable, Codable, Equatable {
    var id: UUID
    var bookId: UUID
    var bookTitle: String
    var passage: String
    var word: String
    var wordLocation: Int
    var wordLength: Int
    var meaning: String
    var tags: [String]
    var isFavorite: Bool
    var createdAt: Date
    var sessionId: UUID?
    var srsInterval: Int
    var srsEase: Double
    var srsReps: Int
    var nextReviewAt: Date?

    init(
        id: UUID = UUID(),
        bookId: UUID,
        bookTitle: String,
        passage: String,
        word: String,
        wordLocation: Int = 0,
        wordLength: Int = 0,
        meaning: String,
        tags: [String] = [],
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        sessionId: UUID? = nil,
        srsInterval: Int = 0,
        srsEase: Double = 2.5,
        srsReps: Int = 0,
        nextReviewAt: Date? = Date()
    ) {
        self.id = id
        self.bookId = bookId
        self.bookTitle = bookTitle
        self.passage = passage
        self.word = word
        self.wordLocation = wordLocation
        self.wordLength = wordLength > 0 ? wordLength : word.count
        self.meaning = meaning
        self.tags = tags
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.sessionId = sessionId
        self.srsInterval = srsInterval
        self.srsEase = srsEase
        self.srsReps = srsReps
        self.nextReviewAt = nextReviewAt
    }

    var isDueForReview: Bool {
        guard let next = nextReviewAt else { return true }
        return next <= Date()
    }

    var wordNSRange: NSRange {
        let ns = passage as NSString
        let loc = min(max(0, wordLocation), ns.length)
        let len = min(max(0, wordLength), max(0, ns.length - loc))
        if len > 0 { return NSRange(location: loc, length: len) }
        let found = ns.range(of: word, options: [.caseInsensitive, .diacriticInsensitive])
        return found.location == NSNotFound ? NSRange(location: 0, length: 0) : found
    }

    var clozePrompt: String {
        let range = wordNSRange
        let ns = passage as NSString
        guard range.length > 0, range.location + range.length <= ns.length else {
            return passage.replacingOccurrences(of: word, with: "_____", options: .caseInsensitive)
        }
        return ns.replacingCharacters(in: range, with: "_____")
    }
}

enum ReviewGrade: String, CaseIterable {
    case forgot
    case almost
    case know

    var title: String {
        switch self {
        case .forgot: return "Forgot"
        case .almost: return "Almost"
        case .know: return "Know"
        }
    }
}

enum PassageText {
    static func sentence(around range: NSRange, in text: String) -> (passage: String, localRange: NSRange) {
        let ns = text as NSString
        guard ns.length > 0 else { return ("", NSRange(location: 0, length: 0)) }
        let loc = min(max(0, range.location), ns.length)
        let len = min(max(0, range.length), max(0, ns.length - loc))
        let wordRange = NSRange(location: loc, length: max(len, 0))

        var start = wordRange.location
        while start > 0 {
            let scalar = ns.substring(with: NSRange(location: start - 1, length: 1))
            if scalar == "." || scalar == "!" || scalar == "?" || scalar == "\n" { break }
            start -= 1
        }
        var end = wordRange.location + wordRange.length
        while end < ns.length {
            let scalar = ns.substring(with: NSRange(location: end, length: 1))
            if scalar == "." || scalar == "!" || scalar == "?" {
                end += 1
                break
            }
            if scalar == "\n" { break }
            end += 1
        }

        var passage = ns.substring(with: NSRange(location: start, length: end - start))
        var leading = 0
        while leading < passage.count, passage[passage.index(passage.startIndex, offsetBy: leading)].isWhitespace {
            leading += 1
        }
        passage = String(passage.dropFirst(leading))
        let localLocation = max(0, wordRange.location - start - leading)
        let localLength = min(wordRange.length, max(0, (passage as NSString).length - localLocation))
        if (passage as NSString).length < 12 {
            return window(around: wordRange, in: text)
        }
        return (passage, NSRange(location: localLocation, length: localLength))
    }

    static func window(around range: NSRange, in text: String) -> (passage: String, localRange: NSRange) {
        let ns = text as NSString
        let pad = 140
        let start = max(0, range.location - pad)
        let end = min(ns.length, range.location + range.length + pad)
        let passage = ns.substring(with: NSRange(location: start, length: end - start))
        return (passage, NSRange(location: range.location - start, length: range.length))
    }
}
