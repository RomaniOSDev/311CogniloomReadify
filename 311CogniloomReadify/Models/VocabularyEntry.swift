import Foundation

struct VocabularyEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var word: String
    var definition: String
    var context: String
    var bookTitle: String
    var createdAt: Date
    var tags: [String]
    var notes: String

    init(
        id: UUID = UUID(),
        word: String,
        definition: String,
        context: String,
        bookTitle: String,
        createdAt: Date = Date(),
        tags: [String] = [],
        notes: String = ""
    ) {
        self.id = id
        self.word = word
        self.definition = definition
        self.context = context
        self.bookTitle = bookTitle
        self.createdAt = createdAt
        self.tags = tags
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        word = try c.decode(String.self, forKey: .word)
        definition = try c.decode(String.self, forKey: .definition)
        context = try c.decodeIfPresent(String.self, forKey: .context) ?? ""
        bookTitle = try c.decode(String.self, forKey: .bookTitle)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
    }
}
