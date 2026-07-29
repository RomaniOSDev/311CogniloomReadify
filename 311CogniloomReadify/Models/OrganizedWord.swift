import Foundation

enum WordTheme: String, Codable, CaseIterable, Identifiable {
    case literary = "Literary"
    case academic = "Academic"
    case everyday = "Everyday"
    case poetic = "Poetic"
    case technical = "Technical"

    var id: String { rawValue }
}

struct OrganizedWord: Identifiable, Codable, Equatable {
    var id: UUID
    var word: String
    var example: String
    var theme: WordTheme
    var createdAt: Date
    var tags: [String]
    var notes: String

    init(
        id: UUID = UUID(),
        word: String,
        example: String,
        theme: WordTheme,
        createdAt: Date = Date(),
        tags: [String] = [],
        notes: String = ""
    ) {
        self.id = id
        self.word = word
        self.example = example
        self.theme = theme
        self.createdAt = createdAt
        self.tags = tags
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        word = try c.decode(String.self, forKey: .word)
        example = try c.decode(String.self, forKey: .example)
        theme = try c.decode(WordTheme.self, forKey: .theme)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
    }
}
