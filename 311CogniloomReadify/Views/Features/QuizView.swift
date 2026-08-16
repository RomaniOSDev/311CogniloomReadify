import SwiftUI
import UniformTypeIdentifiers

struct PassageDeskView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    let bookId: UUID

    @State private var draftText = ""
    @State private var pendingCapture: PendingCapture?
    @State private var showImporter = false
    @State private var showPasteAlert = false

    private var book: ShelfBook? { store.book(id: bookId) }
    private var workspace: BookWorkspace? { store.workspace(for: bookId) }

    var body: some View {
        NavigationStack {
            Group {
                if sizeClass == .regular {
                    HStack(spacing: 0) {
                        deskColumn
                            .frame(maxWidth: .infinity)
                        Rectangle()
                            .fill(Color("AppTextSecondary").opacity(0.2))
                            .frame(width: 1)
                        lexiconColumn
                            .frame(maxWidth: 360)
                    }
                } else {
                    deskColumn
                }
            }
            .navigationTitle(book?.title ?? "Desk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(store.manuscriptTheme.colorScheme.swiftUI, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        persistDesk()
                        store.hidesTabBar = false
                        dismiss()
                    }
                    .foregroundStyle(Color("AppTextSecondary"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Paste from clipboard") { pasteClipboard() }
                        Button("Import .txt or EPUB") { showImporter = true }
                        Button("Clear page") {
                            draftText = ""
                            persistDesk()
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundStyle(Color("AppPrimary"))
                    }
                }
            }
            .screenBackground()
            .safeAreaInset(edge: .top) {
                if let session = store.activeSession, session.bookId == bookId {
                    HStack {
                        SittingChip(session: session)
                        Spacer()
                        Button("End sitting") {
                            store.endSession(save: true)
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AppPrimary"))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color("AppSurface").opacity(0.94))
                }
            }
            .sheet(item: $pendingCapture) { capture in
                CaptureWordSheet(bookId: bookId, capture: capture)
                    .environmentObject(store)
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.plainText, .text, UTType(filenameExtension: "epub") ?? .data],
                allowsMultipleSelection: false
            ) { result in
                if let urls = try? result.get(), let url = urls.first,
                   let text = DocumentTextLoader.load(from: url) {
                    appendText(text)
                }
            }
            .alert("Clipboard is empty", isPresented: $showPasteAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Copy a paragraph from your book, then paste it here.")
            }
            .onAppear {
                store.hidesTabBar = true
                store.setLastOpenedBook(bookId)
                if let pending = store.pendingImportText {
                    appendText(pending)
                    store.pendingImportText = nil
                } else {
                    draftText = book?.deskText ?? ""
                }
            }
            .onDisappear {
                persistDesk()
                store.hidesTabBar = false
            }
        }
        .preferredColorScheme(store.manuscriptTheme.colorScheme.swiftUI)
    }

    private var deskColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tap a word in the page")
                .font(.system(.subheadline, design: .serif).weight(.semibold))
                .foregroundStyle(Color("AppTextSecondary"))
                .padding(.horizontal, 16)
                .padding(.top, 10)

            if draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                EmptyStateView(
                    symbol: "text.cursor",
                    title: "The page is blank",
                    message: "Paste a paragraph you just read, or import a .txt / EPUB. Then tap the word that stopped you.",
                    actionTitle: "Paste paragraph"
                ) {
                    pasteClipboard()
                }
            } else {
                TappablePassageView(
                    text: draftText,
                    highlightRanges: highlightRanges,
                    onWord: { word, range in
                        let extracted = PassageText.sentence(around: range, in: draftText)
                        pendingCapture = PendingCapture(
                            word: word,
                            passage: extracted.passage,
                            wordLocation: extracted.localRange.location,
                            wordLength: extracted.localRange.length
                        )
                    }
                )
                .padding(10)
                .background(Color("AppSurface"))
                .overlay(
                    Rectangle()
                        .strokeBorder(Color("AppTextPrimary").opacity(0.18), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var lexiconColumn: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Lexicon for this book")
                    .font(.system(.subheadline, design: .serif).weight(.bold))
                    .foregroundStyle(Color("AppTextSecondary"))
                if let cards = workspace?.cards, !cards.isEmpty {
                    ForEach(cards) { card in
                        SpineCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(card.word)
                                    .font(.system(.headline, design: .serif).weight(.bold))
                                    .foregroundStyle(Color("AppTextPrimary"))
                                HighlightedPassageText(passage: card.passage, wordRange: card.wordNSRange)
                                Text(card.meaning)
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                        }
                    }
                } else {
                    Text("Tapped words land here, with the sentence they came from.")
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
            .padding(16)
        }
        .clearScrollBackground()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var highlightRanges: [NSRange] {
        guard let cards = workspace?.cards else { return [] }
        let ns = draftText as NSString
        return cards.compactMap { card -> NSRange? in
            let found = ns.range(of: card.word, options: [.caseInsensitive, .diacriticInsensitive])
            return found.location == NSNotFound ? nil : found
        }
    }

    private func pasteClipboard() {
        guard let text = DocumentTextLoader.clipboardText() else {
            showPasteAlert = true
            return
        }
        appendText(text)
    }

    private func appendText(_ text: String) {
        let incoming = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !incoming.isEmpty else { return }
        if draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            draftText = incoming
        } else {
            draftText += "\n\n" + incoming
        }
        persistDesk()
        HapticService.medium()
    }

    private func persistDesk() {
        store.setDeskText(draftText, for: bookId)
    }
}

struct PendingCapture: Identifiable, Equatable {
    let id = UUID()
    let word: String
    let passage: String
    let wordLocation: Int
    let wordLength: Int
}

struct CaptureWordSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    let bookId: UUID
    let capture: PendingCapture

    @State private var meaning = ""
    @State private var tagsText = ""
    @State private var shake = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SoftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(capture.word)
                                .font(.system(.title, design: .serif).weight(.bold))
                                .foregroundStyle(Color("AppTextPrimary"))
                            HighlightedPassageText(
                                passage: capture.passage,
                                wordRange: NSRange(location: capture.wordLocation, length: capture.wordLength)
                            )
                        }
                    }
                    SoftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your gloss")
                                .font(.system(.headline, design: .serif))
                                .foregroundStyle(Color("AppTextPrimary"))
                            TextField("What does it do in this sentence?", text: $meaning, axis: .vertical)
                                .lineLimit(3...6)
                                .foregroundStyle(Color("AppTextPrimary"))
                            TextField("Tags (comma-separated)", text: $tagsText)
                                .foregroundStyle(Color("AppTextPrimary"))
                        }
                    }
                    Button("Keep this mark") { save() }
                        .buttonStyle(PrimaryButtonStyle())
                        .modifier(ShakeEffect(animatableData: CGFloat(shake)))
                }
                .padding(20)
            }
            .clearScrollBackground()
            .navigationTitle("From the page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { KeyboardSupport.dismiss() }
                        .foregroundStyle(Color("AppPrimary"))
                }
            }
            .screenBackground()
            .dismissKeyboardOnTap()
        }
        .preferredColorScheme(store.manuscriptTheme.colorScheme.swiftUI)
    }

    private func save() {
        let tags = tagsText.split(separator: ",").map(String.init)
        if store.addCard(
            bookId: bookId,
            passage: capture.passage,
            word: capture.word,
            wordLocation: capture.wordLocation,
            wordLength: capture.wordLength,
            meaning: meaning,
            tags: tags
        ) != nil {
            dismiss()
        } else {
            withAnimation { shake += 1 }
            HapticService.warning()
        }
    }
}

struct CardEditorSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    let card: PassageCard

    @State private var meaning = ""
    @State private var tagsText = ""
    @State private var shake = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SoftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(card.word)
                                .font(.system(.title, design: .serif).weight(.bold))
                                .foregroundStyle(Color("AppTextPrimary"))
                            HighlightedPassageText(passage: card.passage, wordRange: card.wordNSRange)
                        }
                    }
                    SoftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your gloss")
                                .font(.system(.headline, design: .serif))
                                .foregroundStyle(Color("AppTextPrimary"))
                            TextField("Meaning in this sentence", text: $meaning, axis: .vertical)
                                .lineLimit(3...6)
                            TextField("Tags (comma-separated)", text: $tagsText)
                        }
                    }
                    Button("Save") { save() }
                        .buttonStyle(PrimaryButtonStyle())
                        .modifier(ShakeEffect(animatableData: CGFloat(shake)))
                }
                .padding(20)
            }
            .clearScrollBackground()
            .navigationTitle("Quote card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
            .screenBackground()
            .onAppear {
                meaning = card.meaning
                tagsText = card.tags.joined(separator: ", ")
            }
        }
        .preferredColorScheme(store.manuscriptTheme.colorScheme.swiftUI)
    }

    private func save() {
        var updated = card
        updated.meaning = meaning
        updated.tags = tagsText.split(separator: ",").map(String.init)
        guard !updated.meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            withAnimation { shake += 1 }
            HapticService.warning()
            return
        }
        store.updateCard(updated)
        dismiss()
    }
}
