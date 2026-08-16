import SwiftUI
import PhotosUI
import UIKit

struct ShelfView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showAddBook = false
    @State private var bookRoute: UUID?
    @State private var deskBook: ShelfBook?
    @State private var showImportChooser = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear
                if store.books.isEmpty {
                    EmptyStateView(
                        symbol: "books.vertical.fill",
                        title: "Your shelf is empty",
                        message: "Add the book you are reading. The desk is where you paste a page and tap the word that stopped you.",
                        actionTitle: "Add a Book"
                    ) {
                        showAddBook = true
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            if let session = store.activeSession {
                                sittingBanner(session)
                            }
                            if let quote = store.quoteOfTheDay {
                                SoftCard {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Sentence of the day")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(Color("AppTextSecondary"))
                                        Text("“\(quote.text)”")
                                            .font(.system(.subheadline, design: .serif).weight(.semibold))
                                            .foregroundStyle(Color("AppTextPrimary"))
                                            .italic()
                                            .lineLimit(5)
                                        Text(quote.source)
                                            .font(.caption2.weight(.medium))
                                            .foregroundStyle(Color("AppAccent"))
                                    }
                                }
                            }
                            Text("Working shelf")
                                .font(.system(.subheadline, design: .serif).weight(.semibold))
                                .foregroundStyle(Color("AppTextSecondary"))
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 148), spacing: 14)], spacing: 16) {
                                ForEach(store.shelf) { item in
                                    Button {
                                        HapticService.light()
                                        store.setLastOpenedBook(item.book.id)
                                        bookRoute = item.book.id
                                    } label: {
                                        shelfTile(item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 28)
                    }
                    .clearScrollBackground()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Shelf")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(store.manuscriptTheme.colorScheme.swiftUI, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticService.light()
                        showAddBook = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color("AppPrimary"))
                    }
                }
            }
            .screenBackground()
            .sheet(isPresented: $showAddBook) {
                BookEditorSheet()
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
            .fullScreenCover(item: $deskBook) { book in
                PassageDeskView(bookId: book.id)
                    .environmentObject(store)
            }
            .confirmationDialog("Place imported text", isPresented: $showImportChooser, titleVisibility: .visible) {
                ForEach(store.books) { book in
                    Button(book.title) {
                        if let text = store.pendingImportText {
                            store.appendDeskText(text, for: book.id)
                            store.pendingImportText = nil
                            deskBook = book
                        }
                    }
                }
                Button("New book…") {
                    showAddBook = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .onReceive(NotificationCenter.default.publisher(for: .pendingImportArrived)) { _ in
                if store.books.isEmpty {
                    showAddBook = true
                } else {
                    showImportChooser = true
                }
            }
        }
    }

    private func sittingBanner(_ session: ReadingSession) -> some View {
        Button {
            if let book = store.book(id: session.bookId) {
                deskBook = book
            }
        } label: {
            SoftCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sitting in progress")
                            .font(.system(.subheadline, design: .serif).weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                        Text(session.bookTitle)
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                    Spacer()
                    SittingChip(session: session)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func shelfTile(_ item: BookWorkspace) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            BookCoverPlate(book: item.book)
            Text(item.book.title)
                .font(.system(.subheadline, design: .serif).weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text(item.book.progressLabel)
                .font(.caption2)
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(1)
            HStack(spacing: 8) {
                Label("\(item.cards.count)", systemImage: "text.quote")
                if !item.dueCards.isEmpty {
                    Label("\(item.dueCards.count)", systemImage: "character.textbox")
                        .foregroundStyle(Color("AppAccent"))
                }
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color("AppPrimary"))
        }
    }
}

struct BookEditorSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    var editing: ShelfBook?

    @State private var title = ""
    @State private var author = ""
    @State private var chapter = ""
    @State private var page = ""
    @State private var tint: CoverTint = .ink
    @State private var photoItem: PhotosPickerItem?
    @State private var coverData: Data?
    @State private var shake = 0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Book title", text: $title)
                    TextField("Author (optional)", text: $author)
                    TextField("Chapter / place", text: $chapter)
                    TextField("Page", text: $page)
                        .keyboardType(.numbersAndPunctuation)
                }
                .listRowBackground(Color("AppSurface"))

                Section("Cover") {
                    Picker("Cloth color", selection: $tint) {
                        ForEach(CoverTint.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(coverData == nil ? "Choose a photo" : "Replace photo", systemImage: "camera")
                    }
                    if coverData != nil {
                        Button("Remove photo", role: .destructive) {
                            coverData = nil
                            photoItem = nil
                        }
                    }
                }
                .listRowBackground(Color("AppSurface"))
            }
            .scrollContentBackground(.hidden)
            .background(Color("AppBackground"))
            .navigationTitle(editing == nil ? "Add Book" : "Edit Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(store.manuscriptTheme.colorScheme.swiftUI, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(Color("AppPrimary"))
                        .modifier(ShakeEffect(animatableData: CGFloat(shake)))
                }
            }
            .onAppear {
                if let editing {
                    title = editing.title
                    author = editing.author
                    chapter = editing.chapter
                    page = editing.page
                    tint = editing.coverTint
                    coverData = editing.coverImageData
                }
            }
            .onChange(of: photoItem) { item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        coverData = Self.compressCover(data)
                    }
                }
            }
        }
        .preferredColorScheme(store.manuscriptTheme.colorScheme.swiftUI)
    }

    private func save() {
        if var editing {
            editing.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            editing.author = author.trimmingCharacters(in: .whitespacesAndNewlines)
            editing.chapter = chapter.trimmingCharacters(in: .whitespacesAndNewlines)
            editing.page = page.trimmingCharacters(in: .whitespacesAndNewlines)
            editing.coverTint = tint
            editing.coverImageData = coverData
            guard !editing.title.isEmpty else {
                withAnimation { shake += 1 }
                HapticService.warning()
                return
            }
            store.updateBook(editing)
            dismiss()
        } else if let book = store.addBook(
            title: title,
            author: author,
            chapter: chapter,
            page: page,
            coverTint: tint,
            coverImageData: coverData,
            deskText: store.pendingImportText ?? ""
        ) {
            store.pendingImportText = nil
            store.setLastOpenedBook(book.id)
            dismiss()
        } else {
            withAnimation { shake += 1 }
            HapticService.warning()
        }
    }

    private static func compressCover(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return data }
        let maxSide: CGFloat = 720
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        let rendered = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        return rendered.jpegData(compressionQuality: 0.62)
    }
}

struct SittingSetupSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    let book: ShelfBook
    var onStart: () -> Void

    @State private var minutes = 25
    @State private var goal = 3

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Timed sitting")
                            .font(.system(.headline, design: .serif))
                            .foregroundStyle(Color("AppTextPrimary"))
                        Text("Read \(book.title). When a sentence stops you, tap the word.")
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(Color("AppTextSecondary"))
                        Picker("Length", selection: $minutes) {
                            Text("25 min").tag(25)
                            Text("45 min").tag(45)
                        }
                        .pickerStyle(.segmented)
                        Stepper(value: $goal, in: 1...12) {
                            Text("Goal: \(goal) quote\(goal == 1 ? "" : "s")")
                                .foregroundStyle(Color("AppTextPrimary"))
                        }
                    }
                }
                Button("Start sitting") {
                    store.startSession(book: book, minutes: minutes, quoteGoal: goal)
                    onStart()
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                Spacer()
            }
            .padding(20)
            .navigationTitle("Sitting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
            .screenBackground()
        }
        .preferredColorScheme(store.manuscriptTheme.colorScheme.swiftUI)
    }
}
