import SwiftUI

struct WordsTrackerView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showAdd = false
    @State private var favoritesOnly = false
    @State private var appearOffset: CGFloat = 24
    @State private var showReview = false
    @State private var showQuiz = false
    @State private var showSearch = false
    @State private var editingWord: TrackedWord?
    @State private var bookRoute: String?
    @State private var copiedToast = false

    private var visibleWords: [TrackedWord] {
        let base = store.trackedWords
        if favoritesOnly { return base.filter(\.isFavorite) }
        return base
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.trackedWords.isEmpty {
                    VStack(spacing: 0) {
                        headerStack
                        EmptyStateView(
                            symbol: "book.fill",
                            title: "No words yet",
                            message: "Capture interesting words from the books you are reading.",
                            actionTitle: "Add Word"
                        ) {
                            showAdd = true
                        }
                    }
                } else {
                    VStack(spacing: 0) {
                        headerStack
                        HStack {
                            Text("Your Lexicon")
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
                                    favoritesOnly ? "Favorites" : "All Words",
                                    systemImage: favoritesOnly ? "star.fill" : "star"
                                )
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color("AppPrimary"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color("AppSurface"))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 6)

                        if visibleWords.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "star")
                                    .font(.system(size: 40))
                                    .foregroundStyle(Color("AppTextSecondary"))
                                Text("No favorites yet")
                                    .font(.subheadline)
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            List {
                                ForEach(visibleWords) { item in
                                    wordRow(item)
                                        .listRowBackground(Color.clear)
                                        .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
                                        .listRowSeparator(.hidden)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                store.deleteTrackedWord(item)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                            Button {
                                                editingWord = item
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            .tint(Color("AppAccent"))
                                        }
                                        .swipeActions(edge: .leading) {
                                            Button {
                                                store.toggleFavorite(item)
                                            } label: {
                                                Label(
                                                    item.isFavorite ? "Unfavorite" : "Favorite",
                                                    systemImage: item.isFavorite ? "star.slash.fill" : "star.fill"
                                                )
                                            }
                                            .tint(Color("AppPrimary"))
                                        }
                                }
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                            .scrollDismissesKeyboard(.immediately)
                        }
                    }
                    .offset(y: appearOffset)
                    .opacity(appearOffset == 0 ? 1 : 0)
                    .onAppear {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                            appearOffset = 0
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottomTrailing) {
                Button {
                    HapticService.light()
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color("AppBackground"))
                        .frame(width: 52, height: 52)
                        .background(Color("AppPrimary"))
                        .overlay(
                            Rectangle()
                                .strokeBorder(Color("AppAccent"), lineWidth: 2)
                                .padding(3)
                        )
                        .shadow(color: .black.opacity(0.35), radius: 3, x: 1, y: 2)
                }
                .padding(22)
            }
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
            .navigationTitle("Lexicon")
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
            .sheet(isPresented: $showAdd) {
                AddTrackedWordSheet()
                    .environmentObject(store)
            }
            .sheet(item: $editingWord) { item in
                AddTrackedWordSheet(editing: item)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showReview) {
                ReviewSessionView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showQuiz) {
                QuizView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showSearch) {
                GlobalSearchView()
                    .environmentObject(store)
            }
            .navigationDestination(isPresented: Binding(
                get: { bookRoute != nil },
                set: { if !$0 { bookRoute = nil } }
            )) {
                if let bookRoute, let item = store.bookShelfItem(named: bookRoute) {
                    BookDetailView(book: item)
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
                        Text("\(store.wordsAddedToday)/\(store.dailyGoal)")
                            .font(.system(size: 11, weight: .bold, design: .serif))
                            .foregroundStyle(Color("AppTextPrimary"))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily goal")
                            .font(.system(.subheadline, design: .serif).weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                        Text(store.wordsAddedToday >= store.dailyGoal
                             ? "Goal sealed for today."
                             : "\(store.dailyGoal - store.wordsAddedToday) more to seal the day.")
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

            if let quote = store.quoteOfTheDay {
                SoftCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Quote of the day")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color("AppTextSecondary"))
                        Text("“\(quote.text)”")
                            .font(.system(.subheadline, design: .serif).weight(.semibold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .italic()
                            .lineLimit(4)
                        Text(quote.source)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Color("AppAccent"))
                    }
                }
                .padding(.horizontal, 16)
            }

            HStack(spacing: 8) {
                practiceChip("Review", icon: "rectangle.on.rectangle.angled", badge: store.dueReviewCount) {
                    showReview = true
                }
                practiceChip("Quiz", icon: "questionmark.circle", badge: 0) {
                    showQuiz = true
                }
                practiceChip("Search", icon: "magnifyingglass", badge: 0) {
                    showSearch = true
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func practiceChip(_ title: String, icon: String, badge: Int, action: @escaping () -> Void) -> some View {
        Button {
            HapticService.light()
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if badge > 0 {
                    Text("\(badge)")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color("AppPrimary"))
                        .foregroundStyle(Color("AppBackground"))
                }
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(Color("AppTextPrimary"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color("AppSurface"))
            .overlay(
                Rectangle()
                    .strokeBorder(Color("AppTextPrimary").opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func wordRow(_ item: TrackedWord) -> some View {
        SpineCard {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.word)
                        .font(.system(.headline, design: .serif).weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(item.definition)
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(3)
                        .minimumScaleFactor(0.85)
                    Button {
                        HapticService.light()
                        bookRoute = item.bookTitle
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "book.closed")
                                .font(.caption2)
                            Text(item.bookTitle)
                                .font(.caption.weight(.medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
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
                    if !item.notes.isEmpty {
                        Text(item.notes)
                            .font(.caption2)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .italic()
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: 0)
                Button {
                    store.toggleFavorite(item)
                } label: {
                    Image(systemName: item.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(item.isFavorite ? Color("AppPrimary") : Color("AppTextSecondary"))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            store.toggleFavorite(item)
        }
        .onLongPressGesture {
            store.copyWordToPasteboard(item.word)
            withAnimation { copiedToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation { copiedToast = false }
            }
        }
    }
}

struct AddTrackedWordSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    var editing: TrackedWord?

    @State private var word = ""
    @State private var definition = ""
    @State private var bookTitle = ""
    @State private var tagsText = ""
    @State private var notes = ""
    @State private var shake = 0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Word", text: $word)
                    TextField("Definition", text: $definition, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Book title", text: $bookTitle)
                }
                .listRowBackground(Color("AppSurface"))
                Section("Tags & notes") {
                    TextField("Tags (comma-separated)", text: $tagsText)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
                .listRowBackground(Color("AppSurface"))
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .background(Color("AppBackground"))
            .navigationTitle(editing == nil ? "Add Word" : "Edit Word")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(store.manuscriptTheme.colorScheme.swiftUI, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        KeyboardSupport.dismiss()
                        dismiss()
                    }
                    .foregroundStyle(Color("AppTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(Color("AppPrimary"))
                        .modifier(ShakeEffect(animatableData: CGFloat(shake)))
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { KeyboardSupport.dismiss() }
                        .foregroundStyle(Color("AppPrimary"))
                }
            }
            .dismissKeyboardOnTap()
            .onAppear {
                if let editing {
                    word = editing.word
                    definition = editing.definition
                    bookTitle = editing.bookTitle
                    tagsText = editing.tags.joined(separator: ", ")
                    notes = editing.notes
                }
            }
        }
        .preferredColorScheme(store.manuscriptTheme.colorScheme.swiftUI)
    }

    private func save() {
        let tags = tagsText
            .split(separator: ",")
            .map(String.init)
        if var editing {
            editing.word = word.trimmingCharacters(in: .whitespacesAndNewlines)
            editing.definition = definition.trimmingCharacters(in: .whitespacesAndNewlines)
            editing.bookTitle = bookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            editing.tags = tags
            editing.notes = notes
            guard !editing.word.isEmpty, !editing.definition.isEmpty, !editing.bookTitle.isEmpty else {
                withAnimation { shake += 1 }
                HapticService.warning()
                return
            }
            store.updateTrackedWord(editing)
            dismiss()
        } else if store.addTrackedWord(
            word: word,
            definition: definition,
            bookTitle: bookTitle,
            tags: tags,
            notes: notes
        ) != nil {
            dismiss()
        } else {
            withAnimation { shake += 1 }
            HapticService.warning()
        }
    }
}
