import Foundation
import Compression
import UIKit

enum AppLinks {
    static let privacyPolicy = "https://cogniloom311readify.site/privacy/402"
    static let termsOfUse = "https://cogniloom311readify.site/terms/402"
}

enum DocumentTextLoader {
    static let contentTypes: [String] = ["public.plain-text", "public.text", "public.utf8-plain-text", "org.idpf.epub-container"]

    static func load(from url: URL) -> String? {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        let ext = url.pathExtension.lowercased()
        if ext == "epub" {
            return EPUBTextExtractor.extract(from: url)
        }
        if let utf8 = try? String(contentsOf: url, encoding: .utf8), !utf8.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return utf8
        }
        return try? String(contentsOf: url, encoding: .isoLatin1)
    }

    static func clipboardText() -> String? {
        let text = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (text?.isEmpty == false) ? text : nil
    }
}

enum EPUBTextExtractor {
    static func extract(from url: URL) -> String? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let files = ZipReader.extractTextFiles(from: data)
        guard !files.isEmpty else { return nil }
        let bodies = files
            .filter { $0.name.lowercased().hasSuffix(".xhtml") || $0.name.lowercased().hasSuffix(".html") || $0.name.lowercased().hasSuffix(".htm") }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .map { stripHTML($0.text) }
            .filter { $0.count > 40 }
        let joined = bodies.joined(separator: "\n\n")
        return joined.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : joined
    }

    private static func stripHTML(_ raw: String) -> String {
        var text = raw
        if let start = text.range(of: "<body", options: .caseInsensitive),
           let open = text[start.lowerBound...].firstIndex(of: ">") {
            text = String(text[text.index(after: open)...])
        }
        let patterns = ["(?s)<script[^>]*>.*?</script>", "(?s)<style[^>]*>.*?</style>", "<[^>]+>"]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                text = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: " ")
            }
        }
        text = text
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&quot;", with: "\"")
        let collapsed = text.replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
        return collapsed.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
    }
}

private enum ZipReader {
    struct TextFile {
        let name: String
        let text: String
    }

    static func extractTextFiles(from data: Data) -> [TextFile] {
        var files: [TextFile] = []
        var offset = 0
        let bytes = [UInt8](data)
        while offset + 30 < bytes.count {
            let sig = u32(bytes, offset)
            if sig == 0x02014b50 || sig == 0x06054b50 { break }
            guard sig == 0x04034b50 else { break }
            let flags = u16(bytes, offset + 6)
            let method = u16(bytes, offset + 8)
            var compressed = Int(u32(bytes, offset + 18))
            var uncompressed = Int(u32(bytes, offset + 22))
            let nameLen = Int(u16(bytes, offset + 26))
            let extraLen = Int(u16(bytes, offset + 28))
            let nameStart = offset + 30
            let nameEnd = nameStart + nameLen
            guard nameEnd + extraLen <= bytes.count else { break }
            let name = String(bytes: bytes[nameStart..<nameEnd], encoding: .utf8) ?? "file"
            var dataStart = nameEnd + extraLen
            if flags & 0x08 != 0, compressed == 0 {
                // Data descriptor — skip this entry rather than guess.
                break
            }
            let dataEnd = dataStart + compressed
            guard dataEnd <= bytes.count else { break }
            let payload = Data(bytes[dataStart..<dataEnd])
            let raw: Data?
            if method == 0 {
                raw = payload
            } else if method == 8 {
                raw = inflate(payload, uncompressedSize: max(uncompressed, payload.count * 4))
            } else {
                raw = nil
            }
            if let raw, let text = String(data: raw, encoding: .utf8) ?? String(data: raw, encoding: .isoLatin1) {
                files.append(TextFile(name: name, text: text))
            }
            offset = dataEnd
            _ = uncompressed
        }
        return files
    }

    private static func inflate(_ input: Data, uncompressedSize: Int) -> Data? {
        guard !input.isEmpty else { return nil }
        let destSize = max(uncompressedSize, input.count * 8)
        var output = Data(count: destSize)
        let written = output.withUnsafeMutableBytes { dest -> Int in
            guard let destPtr = dest.bindMemory(to: UInt8.self).baseAddress else { return 0 }
            return input.withUnsafeBytes { src -> Int in
                guard let srcPtr = src.bindMemory(to: UInt8.self).baseAddress else { return 0 }
                return compression_decode_buffer(destPtr, destSize, srcPtr, input.count, nil, COMPRESSION_ZLIB)
            }
        }
        guard written > 0 else { return nil }
        output.count = written
        return output
    }

    private static func u16(_ b: [UInt8], _ i: Int) -> UInt16 {
        UInt16(b[i]) | UInt16(b[i + 1]) << 8
    }

    private static func u32(_ b: [UInt8], _ i: Int) -> UInt32 {
        UInt32(b[i]) | UInt32(b[i + 1]) << 8 | UInt32(b[i + 2]) << 16 | UInt32(b[i + 3]) << 24
    }
}
