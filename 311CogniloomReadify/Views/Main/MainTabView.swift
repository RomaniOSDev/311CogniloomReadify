import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var selected = 0

    private let tabs: [(title: String, icon: String)] = [
        ("Words", "text.book.closed.fill"),
        ("Organize", "books.vertical.fill"),
        ("Badges", "seal.fill"),
        ("Prefs", "slider.horizontal.3")
    ]

    var body: some View {
        ZStack(alignment: .top) {
            Color("AppBackground")
                .ignoresSafeArea()

            // Covers the home-indicator strip under the custom tab bar.
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                Color("AppSurface")
                    .frame(height: 120)
            }
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                Group {
                    switch selected {
                    case 0: WordsTrackerView()
                    case 1: WordOrganizerView()
                    case 2: AchievementsView()
                    default: SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .dismissKeyboardOnTap()

                LedgerTabBar(selected: $selected, items: tabs)
            }

            if let title = store.bannerTitle {
                AchievementBanner(title: title)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
                    .zIndex(10)
            }

            if store.showSuccessFlash {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(Color("AppAccent"))
                    .shadow(color: Color("AppAccent").opacity(0.45), radius: 10)
                    .transition(.scale.combined(with: .opacity))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .allowsHitTesting(false)
                    .zIndex(9)
            }
        }
    }
}
