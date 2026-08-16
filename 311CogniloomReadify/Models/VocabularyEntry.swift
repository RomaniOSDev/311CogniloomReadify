import Foundation

struct ReadingSession: Identifiable, Codable, Equatable {
    var id: UUID
    var bookId: UUID
    var bookTitle: String
    var plannedMinutes: Int
    var quoteGoal: Int
    var startedAt: Date
    var endedAt: Date?
    var elapsedSeconds: Int
    var cardIds: [UUID]

    init(
        id: UUID = UUID(),
        bookId: UUID,
        bookTitle: String,
        plannedMinutes: Int,
        quoteGoal: Int,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        elapsedSeconds: Int = 0,
        cardIds: [UUID] = []
    ) {
        self.id = id
        self.bookId = bookId
        self.bookTitle = bookTitle
        self.plannedMinutes = plannedMinutes
        self.quoteGoal = quoteGoal
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.elapsedSeconds = elapsedSeconds
        self.cardIds = cardIds
    }

    var isActive: Bool { endedAt == nil }

    var remainingSeconds: Int {
        max(0, plannedMinutes * 60 - elapsedSeconds)
    }

    var quotesCaptured: Int { cardIds.count }
}
