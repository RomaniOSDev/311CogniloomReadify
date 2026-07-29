import SwiftUI

struct GlobalSearchView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var bookRoute: String?

    private var results: [SearchResult] {
        store.searchAll(query)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color("AppTextSecondary"))
                    TextField("Search all sources", text: $query)
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
                    Text("Search lexicon, themes, tags, notes, and insights.")
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
                    List {
                        ForEach(results) { hit in
                            resultRow(hit)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .scrollDismissesKeyboard(.immediately)
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

    private func resultRow(_ hit: SearchResult) -> some View {
        SoftCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(hit.word)
                        .font(.system(.headline, design: .serif).weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(1)
                    Spacer()
                    Text(hit.sourceLabel)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color("AppBackground"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color("AppPrimary"))
                }
                Text(hit.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(2)
                if let book = hit.bookTitle {
                    Button {
                        HapticService.light()
                        bookRoute = book
                    } label: {
                        Label(book, systemImage: "book.closed")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color("AppAccent"))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
