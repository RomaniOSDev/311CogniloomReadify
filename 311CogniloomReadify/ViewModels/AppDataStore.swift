import Foundation
import SwiftUI
import UIKit
import Combine

final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    @Published var trackedWords: [TrackedWord] = []
    @Published var wordsList: [OrganizedWord] = []
    @Published var vocabularyEntries: [VocabularyEntry] = []
    @Published var selectedThemeFilter: String = "All"
    @Published var lastAccessedBook: String = ""
    @Published var stats: UserStats = UserStats()
    @Published var unlockedAchievements: Set<String> = []
    @Published var hasSeenOnboarding: Bool = false
    @Published var bannerTitle: String?
    @Published var showSuccessFlash: Bool = false
    @Published var dailyGoal: Int = 5
    @Published var reminderEnabled: Bool = false
    @Published var reminderHour: Int = 20
    @Published var reminderMinute: Int = 0
    @Published var manuscriptTheme: ManuscriptTheme = .inkNight

    private let defaults = UserDefaults.standard
    private let trackedKey = "cr_tracked_words"
    private let wordsListKey = "cr_words_list"
    private let vocabKey = "cr_vocabulary_entries"
    private let themeFilterKey = "cr_selected_theme_filter"
    private let lastBookKey = "cr_last_accessed_book"
    private let statsKey = "cr_stats"
    private let unlockedKey = "cr_unlocked"
    private let onboardingKey = "cr_onboarding"
    private let dailyGoalKey = "cr_daily_goal"
    private let reminderEnabledKey = "cr_reminder_enabled"
    private let reminderHourKey = "cr_reminder_hour"
    private let reminderMinuteKey = "cr_reminder_minute"
    private let manuscriptThemeKey = "cr_manuscript_theme"

    private var bannerQueue: [String] = []
    private var isShowingBanner = false

    private init() {
        load()
    }

    // MARK: - Feature 1: Vocabulary Tracker

    @discardableResult
    func addTrackedWord(
        word: String,
        definition: String,
        bookTitle: String,
        tags: [String] = [],
        notes: String = ""
    ) -> TrackedWord? {
        let w = word.trimmingCharacters(in: .whitespacesAndNewlines)
        let d = definition.trimmingCharacters(in: .whitespacesAndNewlines)
        let b = bookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !w.isEmpty, !d.isEmpty, !b.isEmpty else { return nil }
        let entry = TrackedWord(
            word: w,
            definition: d,
            bookTitle: b,
            tags: Self.normalizeTags(tags),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        trackedWords.insert(entry, at: 0)
        stats.itemsCreated += 1
        recordActivity()
        persist()
        flashSuccess()
        evaluateAchievements()
        HapticService.medium()
        HapticService.play(1104)
        return entry
    }

    func updateTrackedWord(_ item: TrackedWord) {
        guard let idx = trackedWords.firstIndex(where: { $0.id == item.id }) else { return }
        var updated = item
        updated.tags = Self.normalizeTags(item.tags)
        updated.notes = item.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        trackedWords[idx] = updated
        persist()
        HapticService.light()
    }

    func toggleFavorite(_ item: TrackedWord) {
        guard let idx = trackedWords.firstIndex(where: { $0.id == item.id }) else { return }
        trackedWords[idx].isFavorite.toggle()
        persist()
        if trackedWords[idx].isFavorite {
            HapticService.medium()
            HapticService.play(1007)
        } else {
            HapticService.light()
        }
    }

    func deleteTrackedWord(_ item: TrackedWord) {
        trackedWords.removeAll { $0.id == item.id }
        persist()
        HapticService.warning()
    }

    func copyWordToPasteboard(_ text: String) {
        UIPasteboard.general.string = text
        HapticService.medium()
        HapticService.play(1104)
    }

    // MARK: - SRS Review

    var dueReviewWords: [TrackedWord] {
        trackedWords.filter(\.isDueForReview).sorted {
            ($0.nextReviewAt ?? .distantPast) < ($1.nextReviewAt ?? .distantPast)
        }
    }

    var dueReviewCount: Int { dueReviewWords.count }

    func reviewWord(_ item: TrackedWord, grade: ReviewGrade) {
        guard let idx = trackedWords.firstIndex(where: { $0.id == item.id }) else { return }
        var card = trackedWords[idx]
        switch grade {
        case .forgot:
            card.srsReps = 0
            card.srsInterval = 1
            card.srsEase = max(1.3, card.srsEase - 0.2)
        case .almost:
            card.srsReps = max(0, card.srsReps)
            card.srsInterval = max(1, Int(Double(max(card.srsInterval, 1)) * 1.2))
            card.srsEase = max(1.3, card.srsEase - 0.15)
        case .know:
            if card.srsReps == 0 {
                card.srsInterval = 1
            } else if card.srsReps == 1 {
                card.srsInterval = 3
            } else {
                card.srsInterval = max(1, Int(Double(card.srsInterval) * card.srsEase))
            }
            card.srsReps += 1
            card.srsEase = min(3.0, card.srsEase + 0.1)
        }
        card.nextReviewAt = Calendar.current.date(byAdding: .day, value: card.srsInterval, to: Date()) ?? Date()
        trackedWords[idx] = card
        recordActivity()
        persist()
        evaluateAchievements()
        switch grade {
        case .forgot: HapticService.warning()
        case .almost: HapticService.light()
        case .know: HapticService.success()
        }
    }

    // MARK: - Feature 2: Word Organizer

    @discardableResult
    func addOrganizedWord(
        word: String,
        example: String,
        theme: WordTheme,
        tags: [String] = [],
        notes: String = ""
    ) -> OrganizedWord? {
        let w = word.trimmingCharacters(in: .whitespacesAndNewlines)
        let e = example.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !w.isEmpty, !e.isEmpty else { return nil }
        let entry = OrganizedWord(
            word: w,
            example: e,
            theme: theme,
            tags: Self.normalizeTags(tags),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        wordsList.insert(entry, at: 0)
        stats.itemsCreated += 1
        stats.sessionsCompleted += 1
        recordActivity()
        persist()
        flashSuccess()
        evaluateAchievements()
        HapticService.medium()
        HapticService.play(1104)
        return entry
    }

    func updateOrganizedWord(_ item: OrganizedWord) {
        guard let idx = wordsList.firstIndex(where: { $0.id == item.id }) else { return }
        var updated = item
        updated.tags = Self.normalizeTags(item.tags)
        updated.notes = item.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        wordsList[idx] = updated
        persist()
        HapticService.light()
    }

    func deleteOrganizedWord(_ item: OrganizedWord) {
        wordsList.removeAll { $0.id == item.id }
        persist()
        HapticService.warning()
    }

    func setThemeFilter(_ filter: String) {
        selectedThemeFilter = filter
        defaults.set(filter, forKey: themeFilterKey)
        HapticService.light()
    }

    // MARK: - Feature 3: Vocabulary by Book

    @discardableResult
    func addVocabularyEntry(
        word: String,
        definition: String,
        context: String,
        bookTitle: String,
        tags: [String] = [],
        notes: String = ""
    ) -> VocabularyEntry? {
        let w = word.trimmingCharacters(in: .whitespacesAndNewlines)
        let d = definition.trimmingCharacters(in: .whitespacesAndNewlines)
        let c = context.trimmingCharacters(in: .whitespacesAndNewlines)
        let b = bookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !w.isEmpty, !d.isEmpty, !b.isEmpty else { return nil }
        let entry = VocabularyEntry(
            word: w,
            definition: d,
            context: c,
            bookTitle: b,
            tags: Self.normalizeTags(tags),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        vocabularyEntries.insert(entry, at: 0)
        lastAccessedBook = b
        stats.itemsCreated += 1
        stats.sessionsCompleted += 1
        recordActivity()
        persist()
        flashSuccess()
        evaluateAchievements()
        HapticService.medium()
        HapticService.play(1104)
        return entry
    }

    func updateVocabularyEntry(_ item: VocabularyEntry) {
        guard let idx = vocabularyEntries.firstIndex(where: { $0.id == item.id }) else { return }
        var updated = item
        updated.tags = Self.normalizeTags(item.tags)
        updated.notes = item.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        vocabularyEntries[idx] = updated
        persist()
        HapticService.light()
    }

    func deleteVocabularyEntry(_ item: VocabularyEntry) {
        vocabularyEntries.removeAll { $0.id == item.id }
        persist()
        HapticService.warning()
    }

    func setLastAccessedBook(_ book: String) {
        lastAccessedBook = book
        defaults.set(book, forKey: lastBookKey)
    }

    var booksGrouped: [(book: String, entries: [VocabularyEntry])] {
        let grouped = Dictionary(grouping: vocabularyEntries, by: \.bookTitle)
        return grouped
            .map { (book: $0.key, entries: $0.value.sorted { $0.createdAt > $1.createdAt }) }
            .sorted { $0.book.localizedCaseInsensitiveCompare($1.book) == .orderedAscending }
    }

    var bookShelf: [BookShelfItem] {
        var titles = Set(trackedWords.map(\.bookTitle) + vocabularyEntries.map(\.bookTitle))
        titles = Set(titles.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
        return titles
            .map { title in
                BookShelfItem(
                    title: title,
                    tracked: trackedWords.filter { $0.bookTitle.caseInsensitiveCompare(title) == .orderedSame }
                        .sorted { $0.createdAt > $1.createdAt },
                    insights: vocabularyEntries.filter { $0.bookTitle.caseInsensitiveCompare(title) == .orderedSame }
                        .sorted { $0.createdAt > $1.createdAt }
                )
            }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func bookShelfItem(named title: String) -> BookShelfItem? {
        bookShelf.first { $0.title.caseInsensitiveCompare(title) == .orderedSame }
    }

    // MARK: - Search / Quote / Daily goal

    func searchAll(_ query: String) -> [SearchResult] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        let trackedHits = trackedWords.filter {
            $0.word.localizedCaseInsensitiveContains(q)
                || $0.definition.localizedCaseInsensitiveContains(q)
                || $0.bookTitle.localizedCaseInsensitiveContains(q)
                || $0.notes.localizedCaseInsensitiveContains(q)
                || $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(q) })
        }.map(SearchResult.tracked)
        let organizedHits = wordsList.filter {
            $0.word.localizedCaseInsensitiveContains(q)
                || $0.example.localizedCaseInsensitiveContains(q)
                || $0.notes.localizedCaseInsensitiveContains(q)
                || $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(q) })
        }.map(SearchResult.organized)
        let insightHits = vocabularyEntries.filter {
            $0.word.localizedCaseInsensitiveContains(q)
                || $0.definition.localizedCaseInsensitiveContains(q)
                || $0.context.localizedCaseInsensitiveContains(q)
                || $0.bookTitle.localizedCaseInsensitiveContains(q)
                || $0.notes.localizedCaseInsensitiveContains(q)
                || $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(q) })
        }.map(SearchResult.insight)
        return trackedHits + organizedHits + insightHits
    }

    var quoteOfTheDay: (text: String, source: String)? {
        var pool: [(String, String)] = []
        for entry in vocabularyEntries where !entry.context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            pool.append((entry.context, entry.bookTitle))
        }
        for item in wordsList where !item.example.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            pool.append((item.example, item.word))
        }
        guard !pool.isEmpty else { return nil }
        let day = Self.dayString(from: Date())
        var hasher = Hasher()
        hasher.combine(day)
        let idx = abs(hasher.finalize()) % pool.count
        return pool[idx]
    }

    var wordsAddedToday: Int {
        let cal = Calendar.current
        let today = Date()
        let tracked = trackedWords.filter { cal.isDate($0.createdAt, inSameDayAs: today) }.count
        let organized = wordsList.filter { cal.isDate($0.createdAt, inSameDayAs: today) }.count
        let insights = vocabularyEntries.filter { cal.isDate($0.createdAt, inSameDayAs: today) }.count
        return tracked + organized + insights
    }

    var dailyGoalProgress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(1, Double(wordsAddedToday) / Double(dailyGoal))
    }

    var streakProtectionAvailable: Bool {
        let week = Self.weekId(from: Date())
        if stats.streakSkipWeekId != week { return true }
        return !stats.streakSkipUsed
    }

    // MARK: - Preferences

    func setDailyGoal(_ value: Int) {
        dailyGoal = max(1, min(50, value))
        defaults.set(dailyGoal, forKey: dailyGoalKey)
        HapticService.light()
    }

    func setReminderEnabled(_ enabled: Bool) {
        reminderEnabled = enabled
        defaults.set(enabled, forKey: reminderEnabledKey)
        NotificationService.shared.syncReminder(
            enabled: enabled,
            hour: reminderHour,
            minute: reminderMinute,
            goal: dailyGoal
        )
        HapticService.light()
    }

    func setReminderTime(hour: Int, minute: Int) {
        reminderHour = max(0, min(23, hour))
        reminderMinute = max(0, min(59, minute))
        defaults.set(reminderHour, forKey: reminderHourKey)
        defaults.set(reminderMinute, forKey: reminderMinuteKey)
        if reminderEnabled {
            NotificationService.shared.syncReminder(
                enabled: true,
                hour: reminderHour,
                minute: reminderMinute,
                goal: dailyGoal
            )
        }
        HapticService.light()
    }

    func setManuscriptTheme(_ theme: ManuscriptTheme) {
        manuscriptTheme = theme
        defaults.set(theme.rawValue, forKey: manuscriptThemeKey)
        HapticService.light()
    }

    // MARK: - Quiz helpers

    func makeQuizQuestions(count: Int = 8) -> [QuizQuestion] {
        let pool = trackedWords.filter { !$0.definition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard pool.count >= 2 else { return [] }
        let take = min(count, pool.count)
        let selected = Array(pool.shuffled().prefix(take))
        return selected.compactMap { item in
            var options = [item.definition]
            let distractors = pool
                .filter { $0.id != item.id }
                .map(\.definition)
                .shuffled()
            for d in distractors where options.count < 4 {
                if !options.contains(d) { options.append(d) }
            }
            guard options.count >= 2 else { return nil }
            return QuizQuestion(
                id: item.id,
                word: item.word,
                correct: item.definition,
                options: options.shuffled()
            )
        }
    }

    // MARK: - Onboarding / Reset

    func completeOnboarding() {
        hasSeenOnboarding = true
        defaults.set(true, forKey: onboardingKey)
        HapticService.success()
    }

    func resetAll() {
        trackedWords = []
        wordsList = []
        vocabularyEntries = []
        selectedThemeFilter = "All"
        lastAccessedBook = ""
        stats = UserStats()
        unlockedAchievements = []
        bannerTitle = nil
        bannerQueue.removeAll()
        isShowingBanner = false
        persist()
        NotificationCenter.default.post(name: .dataReset, object: nil)
        HapticService.warning()
    }

    // MARK: - Achievements

    func evaluateAchievements() {
        for kind in AchievementKind.allCases {
            guard kind.isUnlocked(stats: stats) else { continue }
            let key = kind.rawValue
            guard !unlockedAchievements.contains(key) else { continue }
            unlockedAchievements.insert(key)
            enqueueBanner(kind.title)
        }
        persist()
    }

    private func enqueueBanner(_ title: String) {
        bannerQueue.append(title)
        presentNextBannerIfNeeded()
    }

    private func presentNextBannerIfNeeded() {
        guard !isShowingBanner, let next = bannerQueue.first else { return }
        bannerQueue.removeFirst()
        isShowingBanner = true
        HapticService.success()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            bannerTitle = next
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            withAnimation(.easeOut(duration: 0.35)) {
                self?.bannerTitle = nil
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self?.isShowingBanner = false
                self?.presentNextBannerIfNeeded()
            }
        }
    }

    func flashSuccess() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            showSuccessFlash = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) {
                self?.showSuccessFlash = false
            }
        }
    }

    // MARK: - Persistence

    /// Streak with one protected skip per ISO week.
    private func recordActivity() {
        let today = Self.dayString(from: Date())
        if stats.lastActiveDay.isEmpty {
            stats.streakDays = 1
            stats.lastActiveDay = today
            return
        }
        if stats.lastActiveDay == today { return }

        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()),
           Self.dayString(from: yesterday) == stats.lastActiveDay {
            stats.streakDays += 1
            stats.lastActiveDay = today
            return
        }

        // Missed at least one day — try weekly streak protection (1 skip).
        let week = Self.weekId(from: Date())
        let skipFreshForWeek = stats.streakSkipWeekId != week
        if skipFreshForWeek || !stats.streakSkipUsed {
            // Protect: keep streak, mark skip used for this week.
            stats.streakDays += 1
            stats.streakSkipWeekId = week
            stats.streakSkipUsed = true
            stats.lastActiveDay = today
            return
        }

        stats.streakDays = 1
        stats.lastActiveDay = today
    }

    private func load() {
        hasSeenOnboarding = defaults.bool(forKey: onboardingKey)
        selectedThemeFilter = defaults.string(forKey: themeFilterKey) ?? "All"
        lastAccessedBook = defaults.string(forKey: lastBookKey) ?? ""
        if defaults.object(forKey: dailyGoalKey) != nil {
            dailyGoal = max(1, defaults.integer(forKey: dailyGoalKey))
        }
        reminderEnabled = defaults.bool(forKey: reminderEnabledKey)
        if defaults.object(forKey: reminderHourKey) != nil {
            reminderHour = defaults.integer(forKey: reminderHourKey)
        }
        if defaults.object(forKey: reminderMinuteKey) != nil {
            reminderMinute = defaults.integer(forKey: reminderMinuteKey)
        }
        if let raw = defaults.string(forKey: manuscriptThemeKey),
           let theme = ManuscriptTheme(rawValue: raw) {
            manuscriptTheme = theme
        }
        if let data = defaults.data(forKey: trackedKey),
           let decoded = try? JSONDecoder().decode([TrackedWord].self, from: data) {
            trackedWords = decoded
        }
        if let data = defaults.data(forKey: wordsListKey),
           let decoded = try? JSONDecoder().decode([OrganizedWord].self, from: data) {
            wordsList = decoded
        }
        if let data = defaults.data(forKey: vocabKey),
           let decoded = try? JSONDecoder().decode([VocabularyEntry].self, from: data) {
            vocabularyEntries = decoded
        }
        if let data = defaults.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode(UserStats.self, from: data) {
            stats = decoded
        }
        if let arr = defaults.array(forKey: unlockedKey) as? [String] {
            unlockedAchievements = Set(arr)
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(trackedWords) {
            defaults.set(data, forKey: trackedKey)
        }
        if let data = try? JSONEncoder().encode(wordsList) {
            defaults.set(data, forKey: wordsListKey)
        }
        if let data = try? JSONEncoder().encode(vocabularyEntries) {
            defaults.set(data, forKey: vocabKey)
        }
        if let data = try? JSONEncoder().encode(stats) {
            defaults.set(data, forKey: statsKey)
        }
        defaults.set(Array(unlockedAchievements), forKey: unlockedKey)
        defaults.set(hasSeenOnboarding, forKey: onboardingKey)
        defaults.set(selectedThemeFilter, forKey: themeFilterKey)
        defaults.set(lastAccessedBook, forKey: lastBookKey)
        defaults.set(dailyGoal, forKey: dailyGoalKey)
        defaults.set(reminderEnabled, forKey: reminderEnabledKey)
        defaults.set(reminderHour, forKey: reminderHourKey)
        defaults.set(reminderMinute, forKey: reminderMinuteKey)
        defaults.set(manuscriptTheme.rawValue, forKey: manuscriptThemeKey)
    }

    private static func normalizeTags(_ tags: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for raw in tags {
            var t = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if t.hasPrefix("#") { t.removeFirst() }
            guard !t.isEmpty, !seen.contains(t) else { continue }
            seen.insert(t)
            result.append(t)
        }
        return result
    }

    private static func dayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func weekId(from date: Date) -> String {
        let cal = Calendar.current
        let year = cal.component(.yearForWeekOfYear, from: date)
        let week = cal.component(.weekOfYear, from: date)
        return String(format: "%d-W%02d", year, week)
    }
}

struct QuizQuestion: Identifiable, Equatable {
    let id: UUID
    let word: String
    let correct: String
    let options: [String]
}
