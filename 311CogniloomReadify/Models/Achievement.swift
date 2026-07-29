import Foundation
import SwiftUI

enum AchievementKind: String, Codable, CaseIterable {
    case firstEntry
    case languageEnthusiast
    case vocabularyBuilder
    case insightfulReader
    case wordCollector
    case devotedLearner
    case expertLinguist
    case activeUser

    var title: String {
        switch self {
        case .firstEntry: return "First Entry"
        case .languageEnthusiast: return "Language Enthusiast"
        case .vocabularyBuilder: return "Vocabulary Builder"
        case .insightfulReader: return "Insightful Reader"
        case .wordCollector: return "Word Collector"
        case .devotedLearner: return "Devoted Learner"
        case .expertLinguist: return "Expert Linguist"
        case .activeUser: return "Active User"
        }
    }

    var detail: String {
        switch self {
        case .firstEntry: return "Log your first vocabulary word"
        case .languageEnthusiast: return "Collect 10 vocabulary entries"
        case .vocabularyBuilder: return "Reach 50 logged words"
        case .insightfulReader: return "Complete 5 reading sessions"
        case .wordCollector: return "Gather 100 unique words"
        case .devotedLearner: return "Keep a 30-day learning streak"
        case .expertLinguist: return "Complete 20 reading sessions"
        case .activeUser: return "Complete 10 reading sessions"
        }
    }

    var icon: String {
        switch self {
        case .firstEntry: return "text.book.closed.fill"
        case .languageEnthusiast: return "globe"
        case .vocabularyBuilder: return "books.vertical.fill"
        case .insightfulReader: return "lightbulb.fill"
        case .wordCollector: return "tray.full.fill"
        case .devotedLearner: return "flame.fill"
        case .expertLinguist: return "graduationcap.fill"
        case .activeUser: return "bolt.fill"
        }
    }

    var goal: Int {
        switch self {
        case .firstEntry: return 1
        case .languageEnthusiast: return 10
        case .vocabularyBuilder: return 50
        case .insightfulReader: return 5
        case .wordCollector: return 100
        case .devotedLearner: return 30
        case .expertLinguist: return 20
        case .activeUser: return 10
        }
    }

    func progress(stats: UserStats) -> Int {
        switch self {
        case .firstEntry, .languageEnthusiast, .vocabularyBuilder, .wordCollector:
            return stats.itemsCreated
        case .insightfulReader, .expertLinguist, .activeUser:
            return stats.sessionsCompleted
        case .devotedLearner:
            return stats.streakDays
        }
    }

    func isUnlocked(stats: UserStats) -> Bool {
        progress(stats: stats) >= goal
    }
}

struct UserStats: Codable, Equatable {
    var itemsCreated: Int = 0
    var sessionsCompleted: Int = 0
    var streakDays: Int = 0
    var lastActiveDay: String = ""
    /// ISO week id when the weekly streak skip was used, e.g. "2026-W31"
    var streakSkipWeekId: String = ""
    var streakSkipUsed: Bool = false

    init(
        itemsCreated: Int = 0,
        sessionsCompleted: Int = 0,
        streakDays: Int = 0,
        lastActiveDay: String = "",
        streakSkipWeekId: String = "",
        streakSkipUsed: Bool = false
    ) {
        self.itemsCreated = itemsCreated
        self.sessionsCompleted = sessionsCompleted
        self.streakDays = streakDays
        self.lastActiveDay = lastActiveDay
        self.streakSkipWeekId = streakSkipWeekId
        self.streakSkipUsed = streakSkipUsed
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        itemsCreated = try c.decodeIfPresent(Int.self, forKey: .itemsCreated) ?? 0
        sessionsCompleted = try c.decodeIfPresent(Int.self, forKey: .sessionsCompleted) ?? 0
        streakDays = try c.decodeIfPresent(Int.self, forKey: .streakDays) ?? 0
        lastActiveDay = try c.decodeIfPresent(String.self, forKey: .lastActiveDay) ?? ""
        streakSkipWeekId = try c.decodeIfPresent(String.self, forKey: .streakSkipWeekId) ?? ""
        streakSkipUsed = try c.decodeIfPresent(Bool.self, forKey: .streakSkipUsed) ?? false
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

enum SearchResult: Identifiable, Equatable {
    case tracked(TrackedWord)
    case organized(OrganizedWord)
    case insight(VocabularyEntry)

    var id: UUID {
        switch self {
        case .tracked(let w): return w.id
        case .organized(let w): return w.id
        case .insight(let w): return w.id
        }
    }

    var word: String {
        switch self {
        case .tracked(let w): return w.word
        case .organized(let w): return w.word
        case .insight(let w): return w.word
        }
    }

    var subtitle: String {
        switch self {
        case .tracked(let w): return w.definition
        case .organized(let w): return w.example
        case .insight(let w): return w.definition
        }
    }

    var sourceLabel: String {
        switch self {
        case .tracked: return "Lexicon"
        case .organized: return "Themes"
        case .insight: return "Insights"
        }
    }

    var bookTitle: String? {
        switch self {
        case .tracked(let w): return w.bookTitle
        case .organized: return nil
        case .insight(let w): return w.bookTitle
        }
    }
}

struct BookShelfItem: Identifiable, Equatable {
    var id: String { title }
    let title: String
    let tracked: [TrackedWord]
    let insights: [VocabularyEntry]

    var totalCount: Int { tracked.count + insights.count }
}

extension Notification.Name {
    static let dataReset = Notification.Name("cr_dataReset")
}
