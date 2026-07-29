import SwiftUI

struct BookDetailView: View {
    @EnvironmentObject private var store: AppDataStore
    let book: BookShelfItem

    private var liveBook: BookShelfItem {
        store.bookShelfItem(named: book.title) ?? book
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SoftCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(liveBook.title)
                            .font(.system(.title3, design: .serif).weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .manuscriptUnderline()
                        HStack(spacing: 16) {
                            Label("\(liveBook.tracked.count) lexicon", systemImage: "text.book.closed")
                            Label("\(liveBook.insights.count) insights", systemImage: "bookmark")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("AppTextSecondary"))
                    }
                }

                if !liveBook.tracked.isEmpty {
                    sectionHeader("Lexicon")
                    ForEach(liveBook.tracked) { item in
                        SpineCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.word)
                                    .font(.system(.headline, design: .serif).weight(.bold))
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Text(item.definition)
                                    .font(.subheadline)
                                    .foregroundStyle(Color("AppTextSecondary"))
                                if !item.tags.isEmpty {
                                    tagRow(item.tags)
                                }
                            }
                        }
                    }
                }

                if !liveBook.insights.isEmpty {
                    sectionHeader("Insights")
                    ForEach(liveBook.insights) { entry in
                        SpineCard(spineColor: Color("AppAccent")) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(entry.word)
                                    .font(.system(.headline, design: .serif).weight(.bold))
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Text(entry.definition)
                                    .font(.subheadline)
                                    .foregroundStyle(Color("AppTextSecondary"))
                                if !entry.context.isEmpty {
                                    Text("“\(entry.context)”")
                                        .font(.caption)
                                        .foregroundStyle(Color("AppAccent"))
                                        .italic()
                                }
                                if !entry.tags.isEmpty {
                                    tagRow(entry.tags)
                                }
                            }
                        }
                    }
                }

                if liveBook.totalCount == 0 {
                    Text("No words linked to this book yet.")
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("Book")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("AppSurface"), for: .navigationBar)
        .toolbarColorScheme(store.manuscriptTheme.colorScheme.swiftUI, for: .navigationBar)
        .screenBackground()
        .onAppear {
            store.setLastAccessedBook(liveBook.title)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(.subheadline, design: .serif).weight(.bold))
            .foregroundStyle(Color("AppTextSecondary"))
            .padding(.top, 4)
    }

    private func tagRow(_ tags: [String]) -> some View {
        HStack(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text("#\(tag)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color("AppPrimary"))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .overlay(
                        Rectangle()
                            .strokeBorder(Color("AppPrimary").opacity(0.45), lineWidth: 1)
                    )
            }
        }
    }
}
