import SwiftUI

struct GlobalSearchView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var editingCard: PassageCard?

    private var results: [PassageCard] {
        store.searchCards(query)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color("AppTextSecondary"))
                    TextField("Search quotes, glosses, books, tags", text: $query)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .submitLabel(.search)
                    if !query.isEmpty {
                        Button {
                            query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(Color("AppSurface"))
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 10)

                if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Search the sentences you lifted from the page.")
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(Color("AppTextSecondary"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(24)
                } else if results.isEmpty {
                    Text("No matches")
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(Color("AppTextSecondary"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(results) { card in
                                Button {
                                    editingCard = card
                                } label: {
                                    SoftCard {
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack {
                                                Text(card.word)
                                                    .font(.system(.headline, design: .serif).weight(.bold))
                                                    .foregroundStyle(Color("AppTextPrimary"))
                                                Spacer()
                                                Text(card.bookTitle)
                                                    .font(.caption2.weight(.bold))
                                                    .foregroundStyle(Color("AppBackground"))
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 3)
                                                    .background(Color("AppPrimary"))
                                            }
                                            HighlightedPassageText(passage: card.passage, wordRange: card.wordNSRange)
                                            Text(card.meaning)
                                                .font(.subheadline)
                                                .foregroundStyle(Color("AppTextSecondary"))
                                                .lineLimit(2)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                    .clearScrollBackground()
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(store.manuscriptTheme.colorScheme.swiftUI, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        KeyboardSupport.dismiss()
                        dismiss()
                    }
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
            .sheet(item: $editingCard) { card in
                CardEditorSheet(card: card)
                    .environmentObject(store)
            }
        }
    }
}
