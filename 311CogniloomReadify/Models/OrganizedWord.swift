import Foundation
import SwiftUI

enum CoverTint: String, Codable, CaseIterable, Identifiable {
    case ink
    case rust
    case moss
    case wine
    case slate
    case gold

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ink: return "Ink"
        case .rust: return "Rust"
        case .moss: return "Moss"
        case .wine: return "Wine"
        case .slate: return "Slate"
        case .gold: return "Gold"
        }
    }

    var color: Color {
        switch self {
        case .ink: return Color(red: 0.16, green: 0.22, blue: 0.28)
        case .rust: return Color(red: 0.55, green: 0.28, blue: 0.16)
        case .moss: return Color(red: 0.22, green: 0.36, blue: 0.24)
        case .wine: return Color(red: 0.42, green: 0.14, blue: 0.20)
        case .slate: return Color(red: 0.30, green: 0.34, blue: 0.40)
        case .gold: return Color(red: 0.62, green: 0.48, blue: 0.22)
        }
    }
}

struct ShelfBook: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var author: String
    var chapter: String
    var page: String
    var coverTint: CoverTint
    var coverImageData: Data?
    var deskText: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        author: String = "",
        chapter: String = "",
        page: String = "",
        coverTint: CoverTint = .ink,
        coverImageData: Data? = nil,
        deskText: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.chapter = chapter
        self.page = page
        self.coverTint = coverTint
        self.coverImageData = coverImageData
        self.deskText = deskText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var progressLabel: String {
        var parts: [String] = []
        let chapterTrim = chapter.trimmingCharacters(in: .whitespacesAndNewlines)
        let pageTrim = page.trimmingCharacters(in: .whitespacesAndNewlines)
        if !chapterTrim.isEmpty { parts.append(chapterTrim) }
        if !pageTrim.isEmpty { parts.append("p. \(pageTrim)") }
        return parts.isEmpty ? "No place marked" : parts.joined(separator: " · ")
    }
}
