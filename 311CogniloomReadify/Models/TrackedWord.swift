import Foundation

struct TrackedWord: Identifiable, Codable, Equatable {
    var id: UUID
    var word: String
    var definition: String
    var bookTitle: String
    var isFavorite: Bool
    var createdAt: Date
    var tags: [String]
    var notes: String
    var srsInterval: Int
    var srsEase: Double
    var srsReps: Int
    var nextReviewAt: Date?

    init(
        id: UUID = UUID(),
        word: String,
        definition: String,
        bookTitle: String,
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        tags: [String] = [],
        notes: String = "",
        srsInterval: Int = 0,
        srsEase: Double = 2.5,
        srsReps: Int = 0,
        nextReviewAt: Date? = Date()
    ) {
        self.id = id
        self.word = word
        self.definition = definition
        self.bookTitle = bookTitle
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.tags = tags
        self.notes = notes
        self.srsInterval = srsInterval
        self.srsEase = srsEase
        self.srsReps = srsReps
        self.nextReviewAt = nextReviewAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        word = try c.decode(String.self, forKey: .word)
        definition = try c.decode(String.self, forKey: .definition)
        bookTitle = try c.decode(String.self, forKey: .bookTitle)
        isFavorite = try c.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        srsInterval = try c.decodeIfPresent(Int.self, forKey: .srsInterval) ?? 0
        srsEase = try c.decodeIfPresent(Double.self, forKey: .srsEase) ?? 2.5
        srsReps = try c.decodeIfPresent(Int.self, forKey: .srsReps) ?? 0
        nextReviewAt = try c.decodeIfPresent(Date.self, forKey: .nextReviewAt) ?? createdAt
    }

    var isDueForReview: Bool {
        guard let next = nextReviewAt else { return true }
        return next <= Date()
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
