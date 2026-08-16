import Foundation
import SwiftUI

enum AchievementKind: String, Codable, CaseIterable {
    case firstQuote
    case threeInSitting
    case firstSitting
    case hourAtDesk
    case weekAtDesk
    case threeBooks
    case tenCloze
    case deepBook

    var title: String {
        switch self {
        case .firstQuote: return "First Underline"
        case .threeInSitting: return "Three From One Sitting"
        case .firstSitting: return "Closed the Timer"
        case .hourAtDesk: return "Hour at the Desk"
        case .weekAtDesk: return "Week of Return"
        case .threeBooks: return "A Working Shelf"
        case .tenCloze: return "Ten Blanks Filled"
        case .deepBook: return "One Book, Twelve Marks"
        }
    }

    var detail: String {
        switch self {
        case .firstQuote: return "Lift the first word out of a sentence"
        case .threeInSitting: return "Capture 3 quotes in a single sitting"
        case .firstSitting: return "Finish your first timed reading sitting"
        case .hourAtDesk: return "Spend 60 minutes across sittings"
        case .weekAtDesk: return "Keep a 7-day desk streak"
        case .threeBooks: return "Keep 3 books on the shelf"
        case .tenCloze: return "Grade 10 cloze reviews"
        case .deepBook: return "Mark 12 quotes in one book"
        }
    }

    var icon: String {
        switch self {
        case .firstQuote: return "pencil.tip"
        case .threeInSitting: return "timer"
        case .firstSitting: return "checkmark.rectangle"
        case .hourAtDesk: return "clock.badge.checkmark"
        case .weekAtDesk: return "flame.fill"
        case .threeBooks: return "books.vertical.fill"
        case .tenCloze: return "character.textbox"
        case .deepBook: return "bookmark.fill"
        }
    }

    var goal: Int {
        switch self {
        case .firstQuote: return 1
        case .threeInSitting: return 3
        case .firstSitting: return 1
        case .hourAtDesk: return 60
        case .weekAtDesk: return 7
        case .threeBooks: return 3
        case .tenCloze: return 10
        case .deepBook: return 12
        }
    }

    func progress(stats: UserStats) -> Int {
        switch self {
        case .firstQuote: return stats.quotesCaptured
        case .threeInSitting: return stats.bestQuotesInSitting
        case .firstSitting: return stats.sessionsCompleted
        case .hourAtDesk: return stats.minutesRead
        case .weekAtDesk: return stats.streakDays
        case .threeBooks: return stats.booksOnShelf
        case .tenCloze: return stats.clozeReviews
        case .deepBook: return stats.deepestBookQuotes
        }
    }

    func isUnlocked(stats: UserStats) -> Bool {
        progress(stats: stats) >= goal
    }
}

struct UserStats: Codable, Equatable {
    var quotesCaptured: Int = 0
    var sessionsCompleted: Int = 0
    var minutesRead: Int = 0
    var clozeReviews: Int = 0
    var bestQuotesInSitting: Int = 0
    var booksOnShelf: Int = 0
    var deepestBookQuotes: Int = 0
    var streakDays: Int = 0
    var lastActiveDay: String = ""
    var streakSkipWeekId: String = ""
    var streakSkipUsed: Bool = false

    init(
        quotesCaptured: Int = 0,
        sessionsCompleted: Int = 0,
        minutesRead: Int = 0,
        clozeReviews: Int = 0,
        bestQuotesInSitting: Int = 0,
        booksOnShelf: Int = 0,
        deepestBookQuotes: Int = 0,
        streakDays: Int = 0,
        lastActiveDay: String = "",
        streakSkipWeekId: String = "",
        streakSkipUsed: Bool = false
    ) {
        self.quotesCaptured = quotesCaptured
        self.sessionsCompleted = sessionsCompleted
        self.minutesRead = minutesRead
        self.clozeReviews = clozeReviews
        self.bestQuotesInSitting = bestQuotesInSitting
        self.booksOnShelf = booksOnShelf
        self.deepestBookQuotes = deepestBookQuotes
        self.streakDays = streakDays
        self.lastActiveDay = lastActiveDay
        self.streakSkipWeekId = streakSkipWeekId
        self.streakSkipUsed = streakSkipUsed
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        quotesCaptured = try c.decodeIfPresent(Int.self, forKey: .quotesCaptured)
            ?? c.decodeIfPresent(Int.self, forKey: .legacyItemsCreated) ?? 0
        sessionsCompleted = try c.decodeIfPresent(Int.self, forKey: .sessionsCompleted) ?? 0
        minutesRead = try c.decodeIfPresent(Int.self, forKey: .minutesRead) ?? 0
        clozeReviews = try c.decodeIfPresent(Int.self, forKey: .clozeReviews) ?? 0
        bestQuotesInSitting = try c.decodeIfPresent(Int.self, forKey: .bestQuotesInSitting) ?? 0
        booksOnShelf = try c.decodeIfPresent(Int.self, forKey: .booksOnShelf) ?? 0
        deepestBookQuotes = try c.decodeIfPresent(Int.self, forKey: .deepestBookQuotes) ?? 0
        streakDays = try c.decodeIfPresent(Int.self, forKey: .streakDays) ?? 0
        lastActiveDay = try c.decodeIfPresent(String.self, forKey: .lastActiveDay) ?? ""
        streakSkipWeekId = try c.decodeIfPresent(String.self, forKey: .streakSkipWeekId) ?? ""
        streakSkipUsed = try c.decodeIfPresent(Bool.self, forKey: .streakSkipUsed) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(quotesCaptured, forKey: .quotesCaptured)
        try c.encode(sessionsCompleted, forKey: .sessionsCompleted)
        try c.encode(minutesRead, forKey: .minutesRead)
        try c.encode(clozeReviews, forKey: .clozeReviews)
        try c.encode(bestQuotesInSitting, forKey: .bestQuotesInSitting)
        try c.encode(booksOnShelf, forKey: .booksOnShelf)
        try c.encode(deepestBookQuotes, forKey: .deepestBookQuotes)
        try c.encode(streakDays, forKey: .streakDays)
        try c.encode(lastActiveDay, forKey: .lastActiveDay)
        try c.encode(streakSkipWeekId, forKey: .streakSkipWeekId)
        try c.encode(streakSkipUsed, forKey: .streakSkipUsed)
    }

    private enum CodingKeys: String, CodingKey {
        case quotesCaptured, sessionsCompleted, minutesRead, clozeReviews
        case bestQuotesInSitting, booksOnShelf, deepestBookQuotes
        case streakDays, lastActiveDay, streakSkipWeekId, streakSkipUsed
        case legacyItemsCreated = "itemsCreated"
    }
}

enum ManuscriptTheme: String, Codable, CaseIterable, Identifiable {
    case inkNight
    case parchment
    case sepiaStudy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inkNight: return "Ink Night"
        case .parchment: return "Parchment"
        case .sepiaStudy: return "Sepia Study"
        }
    }

    var detail: String {
        switch self {
        case .inkNight: return "Dark manuscript desk"
        case .parchment: return "Light paper pages"
        case .sepiaStudy: return "Warm lamp-lit study"
        }
    }

    var colorScheme: ColorSchemePreference {
        switch self {
        case .inkNight, .sepiaStudy: return .dark
        case .parchment: return .light
        }
    }

    var backgroundOpacity: Double {
        switch self {
        case .inkNight: return 0.28
        case .parchment: return 0.18
        case .sepiaStudy: return 0.34
        }
    }

    var usesSepiaWash: Bool { self == .sepiaStudy }
}

enum ColorSchemePreference {
    case light
    case dark

    var swiftUI: ColorScheme {
        switch self {
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct BookWorkspace: Identifiable, Equatable {
    var id: UUID { book.id }
    let book: ShelfBook
    let cards: [PassageCard]

    var dueCards: [PassageCard] {
        cards.filter(\.isDueForReview).sorted {
            ($0.nextReviewAt ?? .distantPast) < ($1.nextReviewAt ?? .distantPast)
        }
    }

    var favoriteCount: Int { cards.filter(\.isFavorite).count }
}

extension Notification.Name {
    static let dataReset = Notification.Name("cr_dataReset")
    static let pendingImportArrived = Notification.Name("cr_pendingImport")
}
