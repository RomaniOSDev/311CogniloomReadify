import SwiftUI

struct WordOrganizerView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var segment = 0
    @State private var searchText = ""
    @State private var showAddWord = false
    @State private var editingWord: OrganizedWord?
    @State private var showAddInsight = false
    @State private var bookRoute: String?
    @State private var copiedToast = false

    private let themeOptions = ["All"] + WordTheme.allCases.map(\.rawValue)

    private var filteredWords: [OrganizedWord] {
        store.wordsList.filter { item in
            let matchesTheme = store.selectedThemeFilter == "All"
                || item.theme.rawValue == store.selectedThemeFilter
            let matchesSearch = searchText.isEmpty
                || item.word.localizedCaseInsensitiveContains(searchText)
                || item.example.localizedCaseInsensitiveContains(searchText)
            return matchesTheme && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Section", selection: $segment) {
                    Text("Themes").tag(0)
                    Text("Insights").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .onChange(of: segment) { _ in
                    HapticService.light()
                }

                if segment == 0 {
                    organizerContent
                } else {
                    insightsContent
                }
            }
            .navigationTitle(segment == 0 ? "Organize" : "By Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(store.manuscriptTheme.colorScheme.swiftUI, for: .navigationBar)
            .screenBackground()
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
            .sheet(isPresented: $showAddWord) {
                OrganizedWordSheet(editing: nil)
                    .environmentObject(store)
            }
            .sheet(item: $editingWord) { item in
                OrganizedWordSheet(editing: item)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showAddInsight) {
                VocabularyEntrySheet()
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

    // MARK: - Themes (Feature 2)

    private var organizerContent: some View {
        Group {
            if store.wordsList.isEmpty {
                EmptyStateView(
                    symbol: "books.vertical.fill",
                    title: "Organize your words",
                    message: "Group vocabulary by theme and keep example sentences close at hand.",
                    actionTitle: "Add Themed Word"
                ) {
                    showAddWord = true
                }
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color("AppTextSecondary"))
                        TextField("Search words or examples", text: $searchText)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .onSubmit { KeyboardSupport.dismiss() }
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                KeyboardSupport.dismiss()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(12)
                    .background(Color("AppSurface"))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)

                    Picker("Theme", selection: Binding(
                        get: { store.selectedThemeFilter },
                        set: { store.setThemeFilter($0) }
                    )) {
                        ForEach(themeOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                    if filteredWords.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 40))
                                .foregroundStyle(Color("AppTextSecondary"))
                            Text("No words match this filter")
                                .font(.subheadline)
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(filteredWords) { item in
                                Button {
                                    HapticService.light()
                                    editingWord = item
                                } label: {
                                    organizedRow(item)
                                }
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        store.deleteOrganizedWord(item)
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
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .scrollDismissesKeyboard(.immediately)
                    }
                }
                .dismissKeyboardOnTap()
                .overlay(alignment: .bottomTrailing) {
                    Button {
                        HapticService.light()
                        KeyboardSupport.dismiss()
                        showAddWord = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .frame(width: 56, height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color("AppPrimary"), Color("AppAccent")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: Color("AppPrimary").opacity(0.45), radius: 12, y: 6)
                    }
                    .padding(22)
                }
            }
        }
    }

    private func organizedRow(_ item: OrganizedWord) -> some View {
        SpineCard(spineColor: Color("AppAccent")) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(item.word)
                        .font(.system(.headline, design: .serif).weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer()
                    Text(item.theme.rawValue)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color("AppPrimary").opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                Text(item.example)
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
                    .italic()
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
                        .lineLimit(2)
                }
            }
        }
        .onLongPressGesture {
            store.copyWordToPasteboard(item.word)
            withAnimation { copiedToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation { copiedToast = false }
            }
        }
    }

    // MARK: - Insights (Feature 3)

    private var insightsContent: some View {
        Group {
            if store.vocabularyEntries.isEmpty {
                EmptyStateView(
                    symbol: "bookmark.fill",
                    title: "Vocabulary by book",
                    message: "Log words with surrounding context from each title you read.",
                    actionTitle: "Add Insight"
                ) {
                    showAddInsight = true
                }
            } else {
                VStack(spacing: 0) {
                    if !store.lastAccessedBook.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(Color("AppPrimary"))
                            Text("Last opened: \(store.lastAccessedBook)")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color("AppTextSecondary"))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }

                    List {
                        ForEach(store.booksGrouped, id: \.book) { group in
                            Section {
                                ForEach(group.entries) { entry in
                                    insightRow(entry)
                                        .listRowBackground(Color.clear)
                                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                        .listRowSeparator(.hidden)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                store.deleteVocabularyEntry(entry)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            } header: {
                                Button {
                                    HapticService.light()
                                    bookRoute = group.book
                                } label: {
                                    HStack {
                                        Image(systemName: "book.fill")
                                            .foregroundStyle(Color("AppPrimary"))
                                        Text(group.book)
                                            .font(.system(.subheadline, design: .serif).weight(.bold))
                                            .foregroundStyle(Color("AppTextPrimary"))
                                        Spacer()
                                        Text("\(group.entries.count)")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(Color("AppAccent"))
                                        Image(systemName: "chevron.right")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(Color("AppTextSecondary"))
                                    }
                                }
                                .buttonStyle(.plain)
                                .textCase(nil)
                                .padding(.bottom, 4)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
                .overlay(alignment: .bottomTrailing) {
                    Button {
                        HapticService.light()
                        showAddInsight = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .frame(width: 56, height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color("AppPrimary"), Color("AppAccent")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: Color("AppPrimary").opacity(0.45), radius: 12, y: 6)
                    }
                    .padding(22)
                }
                .onAppear {
                    if let first = store.booksGrouped.first {
                        store.setLastAccessedBook(first.book)
                    }
                }
            }
        }
    }

    private func insightRow(_ entry: VocabularyEntry) -> some View {
        SpineCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.word)
                    .font(.system(.headline, design: .serif).weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(entry.definition)
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                if !entry.context.isEmpty {
                    Text("“\(entry.context)”")
                        .font(.caption)
                        .foregroundStyle(Color("AppAccent"))
                        .lineLimit(3)
                        .minimumScaleFactor(0.85)
                        .italic()
                }
                if !entry.tags.isEmpty {
                    HStack(spacing: 5) {
                        ForEach(entry.tags.prefix(4), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color("AppPrimary"))
                        }
                    }
                }
            }
        }
        .onLongPressGesture {
            store.copyWordToPasteboard(entry.word)
            withAnimation { copiedToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation { copiedToast = false }
            }
        }
    }
}

struct OrganizedWordSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    var editing: OrganizedWord?

    @State private var word = ""
    @State private var example = ""
    @State private var theme: WordTheme = .literary
    @State private var tagsText = ""
    @State private var notes = ""
    @State private var shake = 0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Word", text: $word)
                    TextField("Example sentence", text: $example, axis: .vertical)
                        .lineLimit(3...6)
                    Picker("Theme", selection: $theme) {
                        ForEach(WordTheme.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
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
                    example = editing.example
                    theme = editing.theme
                    tagsText = editing.tags.joined(separator: ", ")
                    notes = editing.notes
                }
            }
        }
        .preferredColorScheme(store.manuscriptTheme.colorScheme.swiftUI)
    }

    private func save() {
        let trimmedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedExample = example.trimmingCharacters(in: .whitespacesAndNewlines)
        let tags = tagsText.split(separator: ",").map(String.init)
        guard !trimmedWord.isEmpty, !trimmedExample.isEmpty else {
            withAnimation { shake += 1 }
            HapticService.warning()
            return
        }
        if var editing {
            editing.word = trimmedWord
            editing.example = trimmedExample
            editing.theme = theme
            editing.tags = tags
            editing.notes = notes
            store.updateOrganizedWord(editing)
            dismiss()
        } else if store.addOrganizedWord(
            word: trimmedWord,
            example: trimmedExample,
            theme: theme,
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

struct VocabularyEntrySheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var word = ""
    @State private var definition = ""
    @State private var context = ""
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
                        .lineLimit(2...5)
                    TextField("Context from the book", text: $context, axis: .vertical)
                        .lineLimit(2...5)
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
            .navigationTitle("Add Insight")
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
                if !store.lastAccessedBook.isEmpty {
                    bookTitle = store.lastAccessedBook
                }
            }
        }
        .preferredColorScheme(store.manuscriptTheme.colorScheme.swiftUI)
    }

    private func save() {
        let tags = tagsText.split(separator: ",").map(String.init)
        if store.addVocabularyEntry(
            word: word,
            definition: definition,
            context: context,
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
