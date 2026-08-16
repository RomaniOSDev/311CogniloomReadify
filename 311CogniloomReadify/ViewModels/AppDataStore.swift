import Foundation
import SwiftUI
import UIKit
import Combine

final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    @Published var books: [ShelfBook] = []
    @Published var cards: [PassageCard] = []
    @Published var sessions: [ReadingSession] = []
    @Published var activeSession: ReadingSession?
    @Published var stats: UserStats = UserStats()
    @Published var unlockedAchievements: Set<String> = []
    @Published var hasSeenOnboarding: Bool = false
    @Published var bannerTitle: String?
    @Published var showSuccessFlash: Bool = false
    @Published var dailyGoal: Int = 3
    @Published var reminderEnabled: Bool = false
    @Published var reminderHour: Int = 20
    @Published var reminderMinute: Int = 0
    @Published var manuscriptTheme: ManuscriptTheme = .inkNight
    @Published var lastOpenedBookId: UUID?
    @Published var pendingImportText: String?
    @Published var hidesTabBar: Bool = false

    private let defaults = UserDefaults.standard
    private let booksKey = "cr_shelf_books"
    private let cardsKey = "cr_passage_cards"
    private let sessionsKey = "cr_reading_sessions"
    private let activeSessionKey = "cr_active_session"
    private let statsKey = "cr_stats"
    private let unlockedKey = "cr_unlocked"
    private let onboardingKey = "cr_onboarding"
    private let dailyGoalKey = "cr_daily_goal"
    private let reminderEnabledKey = "cr_reminder_enabled"
    private let reminderHourKey = "cr_reminder_hour"
    private let reminderMinuteKey = "cr_reminder_minute"
    private let manuscriptThemeKey = "cr_manuscript_theme"
    private let lastBookIdKey = "cr_last_book_id"
    private let migratedKey = "cr_migrated_desk_v1"

    private var bannerQueue: [String] = []
    private var isShowingBanner = false
    private var sessionTicker: AnyCancellable?

    private init() {
        load()
        migrateLegacyIfNeeded()
        refreshDerivedStats()
        if activeSession != nil {
            startSessionTicker()
        }
    }

    // MARK: - Books

    @discardableResult
    func addBook(
        title: String,
        author: String = "",
        chapter: String = "",
        page: String = "",
        coverTint: CoverTint = .ink,
        coverImageData: Data? = nil,
        deskText: String = ""
    ) -> ShelfBook? {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return nil }
        let book = ShelfBook(
            title: t,
            author: author.trimmingCharacters(in: .whitespacesAndNewlines),
            chapter: chapter.trimmingCharacters(in: .whitespacesAndNewlines),
            page: page.trimmingCharacters(in: .whitespacesAndNewlines),
            coverTint: coverTint,
            coverImageData: coverImageData,
            deskText: deskText
        )
        books.insert(book, at: 0)
        lastOpenedBookId = book.id
        refreshDerivedStats()
        persist()
        HapticService.medium()
        evaluateAchievements()
        return book
    }

    func updateBook(_ book: ShelfBook) {
        guard let idx = books.firstIndex(where: { $0.id == book.id }) else { return }
        var updated = book
        updated.updatedAt = Date()
        books[idx] = updated
        persist()
        HapticService.light()
    }

    func deleteBook(_ book: ShelfBook) {
        books.removeAll { $0.id == book.id }
        cards.removeAll { $0.bookId == book.id }
        if lastOpenedBookId == book.id { lastOpenedBookId = books.first?.id }
        if activeSession?.bookId == book.id { endSession(save: false) }
        refreshDerivedStats()
        persist()
        HapticService.warning()
    }

    func setDeskText(_ text: String, for bookId: UUID) {
        guard let idx = books.firstIndex(where: { $0.id == bookId }) else { return }
        books[idx].deskText = text
        books[idx].updatedAt = Date()
        persist()
    }

    func appendDeskText(_ text: String, for bookId: UUID) {
        guard let idx = books.firstIndex(where: { $0.id == bookId }) else { return }
        let existing = books[idx].deskText.trimmingCharacters(in: .whitespacesAndNewlines)
        let incoming = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !incoming.isEmpty else { return }
        books[idx].deskText = existing.isEmpty ? incoming : existing + "\n\n" + incoming
        books[idx].updatedAt = Date()
        persist()
    }

    func book(id: UUID) -> ShelfBook? {
        books.first { $0.id == id }
    }

    func workspace(for bookId: UUID) -> BookWorkspace? {
        guard let book = book(id: bookId) else { return nil }
        let bookCards = cards
            .filter { $0.bookId == bookId }
            .sorted { $0.createdAt > $1.createdAt }
        return BookWorkspace(book: book, cards: bookCards)
    }

    var shelf: [BookWorkspace] {
        books
            .map { book in
                BookWorkspace(
                    book: book,
                    cards: cards.filter { $0.bookId == book.id }.sorted { $0.createdAt > $1.createdAt }
                )
            }
            .sorted { $0.book.updatedAt > $1.book.updatedAt }
    }

    // MARK: - Cards

    @discardableResult
    func addCard(
        bookId: UUID,
        passage: String,
        word: String,
        wordLocation: Int,
        wordLength: Int,
        meaning: String,
        tags: [String] = []
    ) -> PassageCard? {
        let w = word.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = passage.trimmingCharacters(in: .whitespacesAndNewlines)
        let m = meaning.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !w.isEmpty, !p.isEmpty, !m.isEmpty, let book = book(id: bookId) else { return nil }
        let card = PassageCard(
            bookId: bookId,
            bookTitle: book.title,
            passage: p,
            word: w,
            wordLocation: wordLocation,
            wordLength: wordLength,
            meaning: m,
            tags: Self.normalizeTags(tags),
            sessionId: activeSession?.id
        )
        cards.insert(card, at: 0)
        if var session = activeSession, session.bookId == bookId {
            session.cardIds.append(card.id)
            activeSession = session
        }
        if let idx = books.firstIndex(where: { $0.id == bookId }) {
            books[idx].updatedAt = Date()
        }
        stats.quotesCaptured += 1
        recordActivity()
        refreshDerivedStats()
        persist()
        flashSuccess()
        evaluateAchievements()
        HapticService.medium()
        HapticService.play(1104)
        return card
    }

    func updateCard(_ item: PassageCard) {
        guard let idx = cards.firstIndex(where: { $0.id == item.id }) else { return }
        var updated = item
        updated.tags = Self.normalizeTags(item.tags)
        updated.meaning = item.meaning.trimmingCharacters(in: .whitespacesAndNewlines)
        cards[idx] = updated
        persist()
        HapticService.light()
    }

    func toggleFavorite(_ item: PassageCard) {
        guard let idx = cards.firstIndex(where: { $0.id == item.id }) else { return }
        cards[idx].isFavorite.toggle()
        persist()
        if cards[idx].isFavorite {
            HapticService.medium()
            HapticService.play(1007)
        } else {
            HapticService.light()
        }
    }

    func deleteCard(_ item: PassageCard) {
        cards.removeAll { $0.id == item.id }
        refreshDerivedStats()
        persist()
        HapticService.warning()
    }

    func copyWordToPasteboard(_ text: String) {
        UIPasteboard.general.string = text
        HapticService.medium()
        HapticService.play(1104)
    }

    var dueReviewCards: [PassageCard] {
        cards.filter(\.isDueForReview).sorted {
            ($0.nextReviewAt ?? .distantPast) < ($1.nextReviewAt ?? .distantPast)
        }
    }

    var dueReviewCount: Int { dueReviewCards.count }

    func dueCards(for bookId: UUID) -> [PassageCard] {
        dueReviewCards.filter { $0.bookId == bookId }
    }

    func reviewCard(_ item: PassageCard, grade: ReviewGrade) {
        guard let idx = cards.firstIndex(where: { $0.id == item.id }) else { return }
        var card = cards[idx]
        switch grade {
        case .forgot:
            card.srsReps = 0
            card.srsInterval = 1
            card.srsEase = max(1.3, card.srsEase - 0.2)
        case .almost:
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
        cards[idx] = card
        stats.clozeReviews += 1
        recordActivity()
        persist()
        evaluateAchievements()
        switch grade {
        case .forgot: HapticService.warning()
        case .almost: HapticService.light()
        case .know: HapticService.success()
        }
    }

    // MARK: - Search

    func searchCards(_ query: String) -> [PassageCard] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        return cards.filter {
            $0.word.localizedCaseInsensitiveContains(q)
                || $0.meaning.localizedCaseInsensitiveContains(q)
                || $0.passage.localizedCaseInsensitiveContains(q)
                || $0.bookTitle.localizedCaseInsensitiveContains(q)
                || $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(q) })
        }
    }

    var quoteOfTheDay: (text: String, source: String)? {
        let pool = cards.filter { !$0.passage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !pool.isEmpty else { return nil }
        let day = Self.dayString(from: Date())
        var hasher = Hasher()
        hasher.combine(day)
        let idx = abs(hasher.finalize()) % pool.count
        let card = pool[idx]
        return (card.passage, card.bookTitle)
    }

    var quotesAddedToday: Int {
        let today = Date()
        return cards.filter { Calendar.current.isDate($0.createdAt, inSameDayAs: today) }.count
    }

    var dailyGoalProgress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(1, Double(quotesAddedToday) / Double(dailyGoal))
    }

    var streakProtectionAvailable: Bool {
        let week = Self.weekId(from: Date())
        if stats.streakSkipWeekId != week { return true }
        return !stats.streakSkipUsed
    }

    // MARK: - Sitting / session

    func startSession(book: ShelfBook, minutes: Int, quoteGoal: Int) {
        if activeSession != nil { endSession(save: true) }
        let session = ReadingSession(
            bookId: book.id,
            bookTitle: book.title,
            plannedMinutes: minutes,
            quoteGoal: max(1, quoteGoal)
        )
        activeSession = session
        lastOpenedBookId = book.id
        startSessionTicker()
        persist()
        HapticService.medium()
    }

    func endSession(save: Bool) {
        sessionTicker?.cancel()
        sessionTicker = nil
        guard var session = activeSession else { return }
        session.endedAt = Date()
        session.elapsedSeconds = max(session.elapsedSeconds, Int(Date().timeIntervalSince(session.startedAt)))
        activeSession = nil
        if save {
            sessions.insert(session, at: 0)
            stats.sessionsCompleted += 1
            stats.minutesRead += max(1, session.elapsedSeconds / 60)
            stats.bestQuotesInSitting = max(stats.bestQuotesInSitting, session.quotesCaptured)
            recordActivity()
            evaluateAchievements()
        }
        persist()
        HapticService.success()
    }

    func tickSession() {
        guard var session = activeSession else { return }
        session.elapsedSeconds = Int(Date().timeIntervalSince(session.startedAt))
        activeSession = session
        if session.remainingSeconds == 0 {
            endSession(save: true)
            enqueueBanner("Sitting closed")
        }
    }

    private func startSessionTicker() {
        sessionTicker?.cancel()
        sessionTicker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tickSession()
            }
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

    func setLastOpenedBook(_ id: UUID?) {
        lastOpenedBookId = id
        if let id {
            defaults.set(id.uuidString, forKey: lastBookIdKey)
        } else {
            defaults.removeObject(forKey: lastBookIdKey)
        }
    }

    func ingestImportedText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        pendingImportText = trimmed
        NotificationCenter.default.post(name: .pendingImportArrived, object: nil)
    }

    // MARK: - Onboarding / Reset

    func completeOnboarding() {
        hasSeenOnboarding = true
        defaults.set(true, forKey: onboardingKey)
        HapticService.success()
    }

    func resetAll() {
        books = []
        cards = []
        sessions = []
        activeSession = nil
        sessionTicker?.cancel()
        stats = UserStats()
        unlockedAchievements = []
        bannerTitle = nil
        bannerQueue.removeAll()
        isShowingBanner = false
        lastOpenedBookId = nil
        persist()
        NotificationCenter.default.post(name: .dataReset, object: nil)
        HapticService.warning()
    }

    // MARK: - Achievements

    func evaluateAchievements() {
        refreshDerivedStats()
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

        let week = Self.weekId(from: Date())
        let skipFreshForWeek = stats.streakSkipWeekId != week
        if skipFreshForWeek || !stats.streakSkipUsed {
            stats.streakDays += 1
            stats.streakSkipWeekId = week
            stats.streakSkipUsed = true
            stats.lastActiveDay = today
            return
        }

        stats.streakDays = 1
        stats.lastActiveDay = today
    }

    private func refreshDerivedStats() {
        stats.booksOnShelf = books.count
        stats.quotesCaptured = max(stats.quotesCaptured, cards.count)
        let grouped = Dictionary(grouping: cards, by: \.bookId)
        stats.deepestBookQuotes = grouped.values.map(\.count).max() ?? 0
        if let session = activeSession {
            stats.bestQuotesInSitting = max(stats.bestQuotesInSitting, session.quotesCaptured)
        }
    }

    private func load() {
        hasSeenOnboarding = defaults.bool(forKey: onboardingKey)
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
        if let idString = defaults.string(forKey: lastBookIdKey) {
            lastOpenedBookId = UUID(uuidString: idString)
        }
        if let data = defaults.data(forKey: booksKey),
           let decoded = try? JSONDecoder().decode([ShelfBook].self, from: data) {
            books = decoded
        }
        if let data = defaults.data(forKey: cardsKey),
           let decoded = try? JSONDecoder().decode([PassageCard].self, from: data) {
            cards = decoded
        }
        if let data = defaults.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([ReadingSession].self, from: data) {
            sessions = decoded
        }
        if let data = defaults.data(forKey: activeSessionKey),
           let decoded = try? JSONDecoder().decode(ReadingSession.self, from: data),
           decoded.isActive {
            var live = decoded
            live.elapsedSeconds = Int(Date().timeIntervalSince(live.startedAt))
            if live.remainingSeconds > 0 {
                activeSession = live
            } else {
                live.endedAt = Date()
                sessions.insert(live, at: 0)
            }
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
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(books) { defaults.set(data, forKey: booksKey) }
        if let data = try? encoder.encode(cards) { defaults.set(data, forKey: cardsKey) }
        if let data = try? encoder.encode(sessions) { defaults.set(data, forKey: sessionsKey) }
        if let session = activeSession, let data = try? encoder.encode(session) {
            defaults.set(data, forKey: activeSessionKey)
        } else {
            defaults.removeObject(forKey: activeSessionKey)
        }
        if let data = try? encoder.encode(stats) { defaults.set(data, forKey: statsKey) }
        defaults.set(Array(unlockedAchievements), forKey: unlockedKey)
        defaults.set(hasSeenOnboarding, forKey: onboardingKey)
        defaults.set(dailyGoal, forKey: dailyGoalKey)
        defaults.set(reminderEnabled, forKey: reminderEnabledKey)
        defaults.set(reminderHour, forKey: reminderHourKey)
        defaults.set(reminderMinute, forKey: reminderMinuteKey)
        defaults.set(manuscriptTheme.rawValue, forKey: manuscriptThemeKey)
        if let lastOpenedBookId {
            defaults.set(lastOpenedBookId.uuidString, forKey: lastBookIdKey)
        }
    }

    private func migrateLegacyIfNeeded() {
        guard !defaults.bool(forKey: migratedKey) else { return }
        struct LegacyTracked: Decodable {
            var word: String
            var definition: String
            var bookTitle: String
            var isFavorite: Bool?
            var createdAt: Date?
            var tags: [String]?
            var notes: String?
            var srsInterval: Int?
            var srsEase: Double?
            var srsReps: Int?
            var nextReviewAt: Date?
        }
        struct LegacyOrganized: Decodable {
            var word: String
            var example: String
            var createdAt: Date?
            var tags: [String]?
            var notes: String?
        }
        struct LegacyInsight: Decodable {
            var word: String
            var definition: String
            var context: String?
            var bookTitle: String
            var createdAt: Date?
            var tags: [String]?
            var notes: String?
        }

        var titleToBook: [String: ShelfBook] = Dictionary(uniqueKeysWithValues: books.map {
            ($0.title.lowercased(), $0)
        })

        func bookForTitle(_ raw: String) -> ShelfBook {
            let title = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = (title.isEmpty ? "Unshelved" : title).lowercased()
            if let existing = titleToBook[key] { return existing }
            let created = ShelfBook(title: title.isEmpty ? "Unshelved" : title)
            books.insert(created, at: 0)
            titleToBook[created.title.lowercased()] = created
            return created
        }

        if let data = defaults.data(forKey: "cr_tracked_words"),
           let items = try? JSONDecoder().decode([LegacyTracked].self, from: data) {
            for item in items {
                let book = bookForTitle(item.bookTitle)
                let passage = (item.notes ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let text = passage.isEmpty ? item.word : passage
                let card = PassageCard(
                    bookId: book.id,
                    bookTitle: book.title,
                    passage: text,
                    word: item.word,
                    wordLocation: max(0, text.lowercased().range(of: item.word.lowercased()).map { text.distance(from: text.startIndex, to: $0.lowerBound) } ?? 0),
                    wordLength: item.word.count,
                    meaning: item.definition,
                    tags: item.tags ?? [],
                    isFavorite: item.isFavorite ?? false,
                    createdAt: item.createdAt ?? Date(),
                    srsInterval: item.srsInterval ?? 0,
                    srsEase: item.srsEase ?? 2.5,
                    srsReps: item.srsReps ?? 0,
                    nextReviewAt: item.nextReviewAt
                )
                if !cards.contains(where: { $0.word == card.word && $0.bookId == card.bookId && $0.meaning == card.meaning }) {
                    cards.append(card)
                }
            }
        }

        if let data = defaults.data(forKey: "cr_words_list"),
           let items = try? JSONDecoder().decode([LegacyOrganized].self, from: data) {
            for item in items {
                let book = bookForTitle("Unshelved")
                let passage = item.example
                let card = PassageCard(
                    bookId: book.id,
                    bookTitle: book.title,
                    passage: passage,
                    word: item.word,
                    wordLocation: max(0, passage.lowercased().range(of: item.word.lowercased()).map { passage.distance(from: passage.startIndex, to: $0.lowerBound) } ?? 0),
                    wordLength: item.word.count,
                    meaning: item.notes?.isEmpty == false ? (item.notes ?? item.word) : item.word,
                    tags: item.tags ?? [],
                    createdAt: item.createdAt ?? Date()
                )
                cards.append(card)
            }
        }

        if let data = defaults.data(forKey: "cr_vocabulary_entries"),
           let items = try? JSONDecoder().decode([LegacyInsight].self, from: data) {
            for item in items {
                let book = bookForTitle(item.bookTitle)
                let passage = (item.context ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let text = passage.isEmpty ? item.word : passage
                let card = PassageCard(
                    bookId: book.id,
                    bookTitle: book.title,
                    passage: text,
                    word: item.word,
                    wordLocation: max(0, text.lowercased().range(of: item.word.lowercased()).map { text.distance(from: text.startIndex, to: $0.lowerBound) } ?? 0),
                    wordLength: item.word.count,
                    meaning: item.definition,
                    tags: item.tags ?? [],
                    createdAt: item.createdAt ?? Date()
                )
                cards.append(card)
            }
        }

        cards.sort { $0.createdAt > $1.createdAt }
        defaults.set(true, forKey: migratedKey)
        refreshDerivedStats()
        persist()
        evaluateAchievements()
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

    static func dayString(from date: Date) -> String {
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
