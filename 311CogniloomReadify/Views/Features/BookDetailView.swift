import SwiftUI

struct BookDetailView: View {
    @EnvironmentObject private var store: AppDataStore
    let bookId: UUID

    @State private var showEditor = false
    @State private var showSitting = false
    @State private var showDesk = false
    @State private var editingCard: PassageCard?

    private var workspace: BookWorkspace? {
        store.workspace(for: bookId)
    }

    var body: some View {
        Group {
            if let workspace {
                content(workspace)
            } else {
                Text("This book is no longer on the shelf.")
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .screenBackground()
            }
        }
    }

    private func content(_ workspace: BookWorkspace) -> some View {
        let book = workspace.book
        return ZStack {
            Color.clear
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header(workspace)

                    HStack(spacing: 10) {
                        Button("Open desk") {
                            HapticService.light()
                            showDesk = true
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        Button {
                            HapticService.light()
                            showSitting = true
                        } label: {
                            Text(store.activeSession?.bookId == book.id ? "Sitting on" : "Start sitting")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }

                    if !workspace.dueCards.isEmpty {
                        sectionHeader("Still slipping")
                        Text("Due cloze cards from this book — fill the blank in the original sentence.")
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                        ForEach(workspace.dueCards.prefix(6)) { card in
                            quoteCard(card, slipping: true)
                        }
                    }

                    sectionHeader("Quote pages")
                    if workspace.cards.isEmpty {
                        Text("Paste a paragraph on the desk, then tap the word that stopped you.")
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(Color("AppTextSecondary"))
                    } else {
                        ForEach(workspace.cards) { card in
                            quoteCard(card, slipping: false)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .clearScrollBackground()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("AppSurface"), for: .navigationBar)
        .toolbarColorScheme(store.manuscriptTheme.colorScheme.swiftUI, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showEditor = true
                }
                .foregroundStyle(Color("AppPrimary"))
            }
        }
        .screenBackground()
        .onAppear {
            store.setLastOpenedBook(book.id)
        }
        .sheet(isPresented: $showEditor) {
            BookEditorSheet(editing: book)
                .environmentObject(store)
        }
        .sheet(isPresented: $showSitting) {
            SittingSetupSheet(book: book) {
                showDesk = true
            }
            .environmentObject(store)
        }
        .sheet(item: $editingCard) { card in
            CardEditorSheet(card: card)
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showDesk) {
            PassageDeskView(bookId: book.id)
                .environmentObject(store)
        }
    }

    private func header(_ workspace: BookWorkspace) -> some View {
        SoftCard {
            HStack(alignment: .top, spacing: 14) {
                BookCoverPlate(book: workspace.book)
                    .frame(width: 92)
                VStack(alignment: .leading, spacing: 6) {
                    Text(workspace.book.title)
                        .font(.system(.title3, design: .serif).weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .manuscriptUnderline()
                    if !workspace.book.author.isEmpty {
                        Text(workspace.book.author)
                            .font(.subheadline)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                    Text(workspace.book.progressLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("AppAccent"))
                    HStack(spacing: 12) {
                        Label("\(workspace.cards.count) quotes", systemImage: "text.quote")
                        Label("\(workspace.dueCards.count) due", systemImage: "character.textbox")
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(.subheadline, design: .serif).weight(.bold))
            .foregroundStyle(Color("AppTextSecondary"))
            .padding(.top, 4)
    }

    private func quoteCard(_ card: PassageCard, slipping: Bool) -> some View {
        Button {
            editingCard = card
        } label: {
            SpineCard(spineColor: slipping ? Color("AppAccent") : Color("AppPrimary")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(card.word)
                        .font(.system(.headline, design: .serif).weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                    HighlightedPassageText(passage: card.passage, wordRange: card.wordNSRange)
                    Text(card.meaning)
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                    if !card.tags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(card.tags.prefix(4), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(Color("AppPrimary"))
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                store.toggleFavorite(card)
            } label: {
                Label(card.isFavorite ? "Unfavorite" : "Favorite", systemImage: card.isFavorite ? "star.slash" : "star")
            }
            Button(role: .destructive) {
                store.deleteCard(card)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
