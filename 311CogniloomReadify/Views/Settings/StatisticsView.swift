import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject private var store: AppDataStore

    private var activityDays: [DayCount] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<14).reversed().compactMap { offset -> DayCount? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let quotes = store.cards.filter { calendar.isDate($0.createdAt, inSameDayAs: day) }.count
            return DayCount(date: day, count: quotes)
        }
    }

    private var sittingDays: [DayCount] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<14).reversed().compactMap { offset -> DayCount? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let minutes = store.sessions
                .filter { calendar.isDate($0.startedAt, inSameDayAs: day) }
                .reduce(0) { $0 + max(1, $1.elapsedSeconds / 60) }
            return DayCount(date: day, count: minutes)
        }
    }

    private var topBooks: [BookCount] {
        Dictionary(grouping: store.cards, by: \.bookTitle)
            .map { BookCount(book: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(6)
            .map { $0 }
    }

    private var unlockedCount: Int {
        AchievementKind.allCases.filter {
            store.unlockedAchievements.contains($0.rawValue) || $0.isUnlocked(stats: store.stats)
        }.count
    }

    var body: some View {
        ZStack {
            Color.clear
            ScrollView {
                VStack(spacing: 18) {
                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Overview")
                                .font(.system(.headline, design: .serif))
                                .foregroundStyle(Color("AppTextPrimary"))
                            HStack(spacing: 0) {
                                overviewCell("Quotes", "\(store.stats.quotesCaptured)")
                                Rectangle().fill(Color("AppTextSecondary").opacity(0.3)).frame(width: 1, height: 40)
                                overviewCell("Sittings", "\(store.stats.sessionsCompleted)")
                                Rectangle().fill(Color("AppTextSecondary").opacity(0.3)).frame(width: 1, height: 40)
                                overviewCell("Minutes", "\(store.stats.minutesRead)")
                            }
                            HStack(spacing: 0) {
                                overviewCell("Cloze", "\(store.stats.clozeReviews)")
                                Rectangle().fill(Color("AppTextSecondary").opacity(0.3)).frame(width: 1, height: 40)
                                overviewCell("Seals", "\(unlockedCount)/\(AchievementKind.allCases.count)")
                                Rectangle().fill(Color("AppTextSecondary").opacity(0.3)).frame(width: 1, height: 40)
                                overviewCell("Books", "\(store.books.count)")
                            }
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quotes · 14 days")
                                .font(.system(.headline, design: .serif))
                                .foregroundStyle(Color("AppTextPrimary"))
                            if activityDays.allSatisfy({ $0.count == 0 }) {
                                emptyChartHint("Lift words from a page to see the week.")
                            } else {
                                Chart(activityDays) { item in
                                    BarMark(
                                        x: .value("Day", item.date, unit: .day),
                                        y: .value("Quotes", item.count)
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
                            Text("Minutes at the desk")
                                .font(.system(.headline, design: .serif))
                                .foregroundStyle(Color("AppTextPrimary"))
                            if sittingDays.allSatisfy({ $0.count == 0 }) {
                                emptyChartHint("Finish a timed sitting to log minutes.")
                            } else {
                                Chart(sittingDays) { item in
                                    BarMark(
                                        x: .value("Day", item.date, unit: .day),
                                        y: .value("Minutes", item.count)
                                    )
                                    .foregroundStyle(Color("AppAccent"))
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
                            Text("Quotes by book")
                                .font(.system(.headline, design: .serif))
                                .foregroundStyle(Color("AppTextPrimary"))
                            if topBooks.isEmpty {
                                emptyChartHint("Cards group themselves by the book on the shelf.")
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
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .clearScrollBackground()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Desk log")
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

private struct BookCount: Identifiable {
    let book: String
    let count: Int
    var id: String { book }
}
