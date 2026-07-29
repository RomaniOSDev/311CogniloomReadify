import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject private var store: AppDataStore

    private var activityDays: [DayCount] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dates = store.trackedWords.map(\.createdAt)
            + store.wordsList.map(\.createdAt)
            + store.vocabularyEntries.map(\.createdAt)

        return (0..<14).reversed().compactMap { offset -> DayCount? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let count = dates.filter { calendar.isDate($0, inSameDayAs: day) }.count
            return DayCount(date: day, count: count)
        }
    }

    private var themeBreakdown: [ThemeCount] {
        WordTheme.allCases.map { theme in
            ThemeCount(
                theme: theme.rawValue,
                count: store.wordsList.filter { $0.theme == theme }.count
            )
        }
        .filter { $0.count > 0 }
    }

    private var sourceBreakdown: [SourceCount] {
        [
            SourceCount(source: "Lexicon", count: store.trackedWords.count),
            SourceCount(source: "Themes", count: store.wordsList.count),
            SourceCount(source: "Insights", count: store.vocabularyEntries.count)
        ]
        .filter { $0.count > 0 }
    }

    private var topBooks: [BookCount] {
        var counts: [String: Int] = [:]
        for word in store.trackedWords {
            counts[word.bookTitle, default: 0] += 1
        }
        for entry in store.vocabularyEntries {
            counts[entry.bookTitle, default: 0] += 1
        }
        return counts
            .map { BookCount(book: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(6)
            .map { $0 }
    }

    private var favoritesCount: Int {
        store.trackedWords.filter(\.isFavorite).count
    }

    private var unlockedCount: Int {
        AchievementKind.allCases.filter {
            store.unlockedAchievements.contains($0.rawValue) || $0.isUnlocked(stats: store.stats)
        }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overview")
                            .font(.system(.headline, design: .serif))
                            .foregroundStyle(Color("AppTextPrimary"))
                        HStack(spacing: 0) {
                            overviewCell("Words", "\(store.stats.itemsCreated)")
                            Rectangle().fill(Color("AppTextSecondary").opacity(0.3)).frame(width: 1, height: 40)
                            overviewCell("Sessions", "\(store.stats.sessionsCompleted)")
                            Rectangle().fill(Color("AppTextSecondary").opacity(0.3)).frame(width: 1, height: 40)
                            overviewCell("Streak", "\(store.stats.streakDays)")
                        }
                        HStack(spacing: 0) {
                            overviewCell("Favorites", "\(favoritesCount)")
                            Rectangle().fill(Color("AppTextSecondary").opacity(0.3)).frame(width: 1, height: 40)
                            overviewCell("Badges", "\(unlockedCount)/\(AchievementKind.allCases.count)")
                            Rectangle().fill(Color("AppTextSecondary").opacity(0.3)).frame(width: 1, height: 40)
                            overviewCell("Books", "\(topBooks.count)")
                        }
                    }
                }

                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Activity · 14 days")
                            .font(.system(.headline, design: .serif))
                            .foregroundStyle(Color("AppTextPrimary"))
                        if activityDays.allSatisfy({ $0.count == 0 }) {
                            emptyChartHint("Add words to see daily activity.")
                        } else {
                            Chart(activityDays) { item in
                                BarMark(
                                    x: .value("Day", item.date, unit: .day),
                                    y: .value("Words", item.count)
                                )
                                .foregroundStyle(Color("AppPrimary"))
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day, count: 3)) { value in
                                    AxisGridLine().foregroundStyle(Color("AppTextSecondary").opacity(0.15))
                                    AxisValueLabel {
                                        if let date = value.as(Date.self) {
                                            Text(date, format: .dateTime.day().month(.abbreviated))
                                                .font(.caption2)
                                                .foregroundStyle(Color("AppTextSecondary"))
                                        }
                                    }
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading) { _ in
                                    AxisGridLine().foregroundStyle(Color("AppTextSecondary").opacity(0.15))
                                    AxisValueLabel()
                                        .font(.caption2)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                            }
                            .frame(height: 180)
                        }
                    }
                }

                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("By Source")
                            .font(.system(.headline, design: .serif))
                            .foregroundStyle(Color("AppTextPrimary"))
                        if sourceBreakdown.isEmpty {
                            emptyChartHint("No vocabulary logged yet.")
                        } else {
                            Chart(sourceBreakdown) { item in
                                BarMark(
                                    x: .value("Count", item.count),
                                    y: .value("Source", item.source)
                                )
                                .foregroundStyle(by: .value("Source", item.source))
                            }
                            .chartForegroundStyleScale([
                                "Lexicon": Color("AppPrimary"),
                                "Themes": Color("AppAccent"),
                                "Insights": Color("AppTextSecondary")
                            ])
                            .chartLegend(.hidden)
                            .chartXAxis {
                                AxisMarks { _ in
                                    AxisGridLine().foregroundStyle(Color("AppTextSecondary").opacity(0.15))
                                    AxisValueLabel()
                                        .font(.caption2)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                            }
                            .chartYAxis {
                                AxisMarks { _ in
                                    AxisValueLabel()
                                        .font(.caption2)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                            }
                            .frame(height: CGFloat(max(sourceBreakdown.count, 1)) * 40 + 24)
                        }
                    }
                }

                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Themes")
                            .font(.system(.headline, design: .serif))
                            .foregroundStyle(Color("AppTextPrimary"))
                        if themeBreakdown.isEmpty {
                            emptyChartHint("Organize words by theme to unlock this chart.")
                        } else {
                            Chart(themeBreakdown) { item in
                                BarMark(
                                    x: .value("Count", item.count),
                                    y: .value("Theme", item.theme)
                                )
                                .foregroundStyle(Color("AppAccent"))
                            }
                            .chartXAxis {
                                AxisMarks { _ in
                                    AxisGridLine().foregroundStyle(Color("AppTextSecondary").opacity(0.15))
                                    AxisValueLabel()
                                        .font(.caption2)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                            }
                            .chartYAxis {
                                AxisMarks { _ in
                                    AxisValueLabel()
                                        .font(.caption2)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                            }
                            .frame(height: CGFloat(max(themeBreakdown.count, 1)) * 36 + 24)
                        }
                    }
                }

                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Top Books")
                            .font(.system(.headline, design: .serif))
                            .foregroundStyle(Color("AppTextPrimary"))
                        if topBooks.isEmpty {
                            emptyChartHint("Log words with book titles to rank them.")
                        } else {
                            Chart(topBooks) { item in
                                BarMark(
                                    x: .value("Count", item.count),
                                    y: .value("Book", item.book)
                                )
                                .foregroundStyle(Color("AppPrimary").opacity(0.85))
                            }
                            .chartXAxis {
                                AxisMarks { _ in
                                    AxisGridLine().foregroundStyle(Color("AppTextSecondary").opacity(0.15))
                                    AxisValueLabel()
                                        .font(.caption2)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                            }
                            .chartYAxis {
                                AxisMarks { _ in
                                    AxisValueLabel()
                                        .font(.caption2)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                            }
                            .frame(height: CGFloat(max(topBooks.count, 1)) * 36 + 24)
                        }
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 12)
        }
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("AppSurface"), for: .navigationBar)
        .toolbarColorScheme(store.manuscriptTheme.colorScheme.swiftUI, for: .navigationBar)
        .screenBackground()
        .dismissKeyboardOnTap()
    }

    private func overviewCell(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .serif).weight(.bold))
                .foregroundStyle(Color("AppPrimary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private func emptyChartHint(_ text: String) -> some View {
        Text(text)
            .font(.system(.subheadline, design: .serif))
            .foregroundStyle(Color("AppTextSecondary"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 20)
    }
}

private struct DayCount: Identifiable {
    let date: Date
    let count: Int
    var id: Date { date }
}

private struct ThemeCount: Identifiable {
    let theme: String
    let count: Int
    var id: String { theme }
}

private struct SourceCount: Identifiable {
    let source: String
    let count: Int
    var id: String { source }
}

private struct BookCount: Identifiable {
    let book: String
    let count: Int
    var id: String { book }
}
