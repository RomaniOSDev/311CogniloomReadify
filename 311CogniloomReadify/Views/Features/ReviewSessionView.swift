import SwiftUI

struct ClozeReviewView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var queue: [PassageCard] = []
    @State private var typed = ""
    @State private var revealed = false
    @State private var typedCorrect: Bool?
    @State private var reviewed = 0
    @State private var bookFilter: UUID?
    @FocusState private var fieldFocused: Bool

    private var source: [PassageCard] {
        if let bookFilter {
            return store.dueCards(for: bookFilter)
        }
        return store.dueReviewCards
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear
                if queue.isEmpty {
                    emptyState
                } else if let card = queue.first {
                    cardBody(card)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Cloze")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(store.manuscriptTheme.colorScheme.swiftUI, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("All books") { bookFilter = nil; reload() }
                        ForEach(store.books) { book in
                            Button(book.title) {
                                bookFilter = book.id
                                reload()
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                            .foregroundStyle(Color("AppPrimary"))
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { KeyboardSupport.dismiss() }
                        .foregroundStyle(Color("AppPrimary"))
                }
            }
            .screenBackground()
            .onAppear { reload() }
            .onChange(of: bookFilter) { _ in reload() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: reviewed == 0 ? "character.textbox" : "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color("AppPrimary"))
            Text(reviewed == 0 ? "Nothing due" : "Sitting of blanks is done")
                .font(.system(.title3, design: .serif).weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))
            Text(reviewed == 0
                 ? "When you lift a word from a page, it returns here as a sentence with a hole."
                 : "You filled \(reviewed) blank\(reviewed == 1 ? "" : "s").")
                .font(.system(.body, design: .serif))
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func cardBody(_ card: PassageCard) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("\(reviewed + 1) of \(reviewed + queue.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))

                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(card.bookTitle)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color("AppAccent"))
                        Text(revealed ? card.passage : card.clozePrompt)
                            .font(.system(.title3, design: .serif).weight(.semibold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .fixedSize(horizontal: false, vertical: true)
                        if revealed {
                            Divider().background(Color("AppTextSecondary").opacity(0.25))
                            Text(card.word)
                                .font(.system(.title2, design: .serif).weight(.bold))
                                .foregroundStyle(Color("AppPrimary"))
                            Text(card.meaning)
                                .font(.system(.body, design: .serif))
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !revealed {
                    SoftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Type the missing word")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color("AppTextSecondary"))
                            TextField("The word from the sentence", text: $typed)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($fieldFocused)
                                .submitLabel(.done)
                                .onSubmit { checkTyped(card) }
                            Button("Check") { checkTyped(card) }
                                .buttonStyle(PrimaryButtonStyle())
                            Button("Show the word") {
                                withAnimation(.easeInOut(duration: 0.2)) { revealed = true }
                                HapticService.light()
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color("AppTextSecondary"))
                            .frame(maxWidth: .infinity)
                        }
                    }
                    if typedCorrect == false {
                        Text("Not that spelling — reveal and grade honestly.")
                            .font(.caption)
                            .foregroundStyle(Color.red.opacity(0.85))
                    }
                } else {
                    HStack(spacing: 10) {
                        gradeButton(.forgot)
                        gradeButton(.almost)
                        gradeButton(.know)
                    }
                    if typedCorrect == true {
                        Text("You filled the blank. Grade how sure you were.")
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 20)
        }
        .clearScrollBackground()
    }

    private func checkTyped(_ card: PassageCard) {
        let guess = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !guess.isEmpty else {
            HapticService.warning()
            return
        }
        let ok = guess.compare(card.word, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        typedCorrect = ok
        if ok {
            HapticService.success()
            withAnimation(.easeInOut(duration: 0.2)) { revealed = true }
        } else {
            HapticService.warning()
        }
    }

    private func gradeButton(_ grade: ReviewGrade) -> some View {
        Button {
            guard let card = queue.first else { return }
            store.reviewCard(card, grade: grade)
            withAnimation(.easeInOut(duration: 0.2)) {
                _ = queue.removeFirst()
                reviewed += 1
                revealed = false
                typed = ""
                typedCorrect = nil
            }
        } label: {
            Text(grade.title)
                .font(.system(.subheadline, design: .serif).weight(.bold))
                .foregroundStyle(Color("AppBackground"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(gradeColor(grade))
                .overlay(
                    Rectangle()
                        .strokeBorder(Color("AppAccent").opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func gradeColor(_ grade: ReviewGrade) -> Color {
        switch grade {
        case .forgot: return Color.red.opacity(0.85)
        case .almost: return Color("AppAccent")
        case .know: return Color("AppPrimary")
        }
    }

    private func reload() {
        queue = source
        revealed = false
        typed = ""
        typedCorrect = nil
        reviewed = 0
    }
}
