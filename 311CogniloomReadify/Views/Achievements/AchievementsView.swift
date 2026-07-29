import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var store: AppDataStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Reading Ledger")
                                .font(.system(.title3, design: .serif).weight(.bold))
                                .foregroundStyle(Color("AppTextPrimary"))
                                .manuscriptUnderline()
                            HStack(spacing: 0) {
                                ledgerMetric("Words", store.stats.itemsCreated)
                                Rectangle().fill(Color("AppTextSecondary").opacity(0.3)).frame(width: 1, height: 36)
                                ledgerMetric("Sessions", store.stats.sessionsCompleted)
                                Rectangle().fill(Color("AppTextSecondary").opacity(0.3)).frame(width: 1, height: 36)
                                ledgerMetric("Streak", store.stats.streakDays)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    ForEach(Array(AchievementKind.allCases.enumerated()), id: \.element.rawValue) { index, kind in
                        ledgerRow(kind, index: index + 1)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                    }
                    .padding(.bottom, 20)
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("Ledger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(store.manuscriptTheme.colorScheme.swiftUI, for: .navigationBar)
            .screenBackground()
            .dismissKeyboardOnTap()
        }
    }

    private func ledgerMetric(_ title: String, _ value: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(.title3, design: .serif).weight(.bold))
                .foregroundStyle(Color("AppPrimary"))
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private func ledgerRow(_ kind: AchievementKind, index: Int) -> some View {
        let unlocked = store.unlockedAchievements.contains(kind.rawValue) || kind.isUnlocked(stats: store.stats)
        let progress = min(kind.progress(stats: store.stats), kind.goal)
        return HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Text(String(format: "%02d", index))
                    .font(.system(.caption, design: .serif).weight(.bold))
                    .foregroundStyle(Color("AppTextSecondary"))
                ZStack {
                    Circle()
                        .strokeBorder(unlocked ? Color("AppPrimary") : Color("AppTextSecondary").opacity(0.4), lineWidth: 2)
                        .frame(width: 36, height: 36)
                    Image(systemName: kind.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(unlocked ? Color("AppPrimary") : Color("AppTextSecondary"))
                }
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(kind.title)
                        .font(.system(.subheadline, design: .serif).weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                    Text(unlocked ? "SEALED" : "OPEN")
                        .font(.system(size: 9, weight: .heavy, design: .serif))
                        .foregroundStyle(unlocked ? Color("AppBackground") : Color("AppTextSecondary"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(unlocked ? Color("AppPrimary") : Color.clear)
                        .overlay(
                            Rectangle()
                                .strokeBorder(Color("AppTextSecondary").opacity(unlocked ? 0 : 0.45), lineWidth: 1)
                        )
                }
                Text(kind.detail)
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color("AppTextSecondary").opacity(0.2))
                            .frame(height: 4)
                        Rectangle()
                            .fill(Color("AppAccent"))
                            .frame(width: geo.size.width * CGFloat(progress) / CGFloat(max(kind.goal, 1)), height: 4)
                    }
                }
                .frame(height: 4)
                Text("\(progress)/\(kind.goal)")
                    .font(.caption2)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("AppSurface"))
            .overlay(
                Rectangle()
                    .strokeBorder(Color("AppTextPrimary").opacity(0.15), lineWidth: 1)
            )
            .opacity(unlocked ? 1 : 0.78)
        }
    }
}
