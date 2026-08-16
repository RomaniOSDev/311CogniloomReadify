import SwiftUI

struct InboxView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var favoritesOnly = false
    @State private var showSearch = false
    @State private var editingCard: PassageCard?
    @State private var bookRoute: UUID?
    @State private var copiedToast = false

    private var visibleCards: [PassageCard] {
        let base = store.cards.sorted { $0.createdAt > $1.createdAt }
        if favoritesOnly { return base.filter(\.isFavorite) }
        return base
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear
                if store.cards.isEmpty {
                    VStack(spacing: 0) {
                        headerStack
                        VStack(spacing: 16) {
                            Image(systemName: "tray")
                                .font(.system(size: 40))
                                .foregroundStyle(Color("AppPrimary"))
                            Text("Inbox is empty")
                                .font(.system(.title3, design: .serif).weight(.bold))
                                .foregroundStyle(Color("AppTextPrimary"))
                            Text("Open a book on the shelf, paste a paragraph, and tap a word. Cards land here.")
                                .font(.system(.body, design: .serif))
                                .foregroundStyle(Color("AppTextSecondary"))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    VStack(spacing: 0) {
                        headerStack
                        HStack {
                            Text("Recent marks")
                                .font(.system(.subheadline, design: .serif).weight(.semibold))
                                .foregroundStyle(Color("AppTextSecondary"))
                            Spacer()
                            Button {
                                HapticService.light()
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    favoritesOnly.toggle()
                                }
                            } label: {
                                Label(
                                    favoritesOnly ? "Favorites" : "All cards",
                                    systemImage: favoritesOnly ? "star.fill" : "star"
                                )
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color("AppPrimary"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color("AppSurface"))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 6)

                        if visibleCards.isEmpty {
                            Text("No favorites yet")
                                .font(.system(.subheadline, design: .serif))
                                .foregroundStyle(Color("AppTextSecondary"))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(visibleCards) { item in
                                        cardRow(item)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 24)
                            }
                            .clearScrollBackground()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .top) {
                if copiedToast {
                    Text("Copied")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AppBackground"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color("AppPrimary"))
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(store.manuscriptTheme.colorScheme.swiftUI, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticService.light()
                        showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color("AppPrimary"))
                    }
                }
            }
            .screenBackground()
            .sheet(isPresented: $showSearch) {
                GlobalSearchView()
                    .environmentObject(store)
            }
            .sheet(item: $editingCard) { card in
                CardEditorSheet(card: card)
                    .environmentObject(store)
            }
            .navigationDestination(isPresented: Binding(
                get: { bookRoute != nil },
                set: { if !$0 { bookRoute = nil } }
            )) {
                if let bookRoute {
                    BookDetailView(bookId: bookRoute)
                }
            }
        }
    }

    private var headerStack: some View {
        VStack(spacing: 10) {
            SoftCard {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .strokeBorder(Color("AppTextSecondary").opacity(0.25), lineWidth: 5)
                            .frame(width: 54, height: 54)
                        Circle()
                            .trim(from: 0, to: store.dailyGoalProgress)
                            .stroke(Color("AppPrimary"), style: StrokeStyle(lineWidth: 5, lineCap: .butt))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 54, height: 54)
                        Text("\(store.quotesAddedToday)/\(store.dailyGoal)")
                            .font(.system(size: 11, weight: .bold, design: .serif))
                            .foregroundStyle(Color("AppTextPrimary"))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quotes today")
                            .font(.system(.subheadline, design: .serif).weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                        Text(store.quotesAddedToday >= store.dailyGoal
                             ? "Day sealed."
                             : "\(store.dailyGoal - store.quotesAddedToday) more quotes to seal the day.")
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .lineLimit(2)
                        HStack(spacing: 6) {
                            Image(systemName: store.streakProtectionAvailable ? "shield.lefthalf.filled" : "shield.fill")
                                .font(.caption2)
                            Text(store.streakProtectionAvailable ? "Streak shield ready" : "Shield used this week")
                                .font(.caption2.weight(.semibold))
                        }
                        .foregroundStyle(Color("AppAccent"))
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            if let session = store.activeSession {
                SittingChip(session: session)
                    .padding(.horizontal, 16)
            }
        }
    }

    private func cardRow(_ item: PassageCard) -> some View {
        SpineCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(item.word)
                        .font(.system(.headline, design: .serif).weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                    Spacer()
                    Button {
                        store.toggleFavorite(item)
                    } label: {
                        Image(systemName: item.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(item.isFavorite ? Color("AppPrimary") : Color("AppTextSecondary"))
                    }
                    .buttonStyle(.plain)
                }
                HighlightedPassageText(passage: item.passage, wordRange: item.wordNSRange)
                Text(item.meaning)
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(3)
                Button {
                    HapticService.light()
                    bookRoute = item.bookId
                } label: {
                    Label(item.bookTitle, systemImage: "book.closed")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color("AppAccent"))
                }
                .buttonStyle(.plain)
                if !item.tags.isEmpty {
                    HStack(spacing: 5) {
                        ForEach(item.tags.prefix(4), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color("AppPrimary"))
                        }
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            editingCard = item
        }
        .onLongPressGesture {
            store.copyWordToPasteboard(item.word)
            withAnimation { copiedToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation { copiedToast = false }
            }
        }
        .contextMenu {
            Button { editingCard = item } label: { Label("Edit gloss", systemImage: "pencil") }
            Button(role: .destructive) { store.deleteCard(item) } label: { Label("Delete", systemImage: "trash") }
        }
    }
}
