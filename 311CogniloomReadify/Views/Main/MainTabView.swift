import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var selected = 0

    private let tabs: [(title: String, icon: String)] = [
        ("Shelf", "books.vertical.fill"),
        ("Inbox", "tray.full.fill"),
        ("Cloze", "character.textbox"),
        ("Prefs", "slider.horizontal.3")
    ]

    var body: some View {
        ZStack(alignment: .top) {
            Color("AppBackground")
                .ignoresSafeArea()

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
                    case 0: ShelfView()
                    case 1: InboxView()
                    case 2: ClozeReviewView()
                    default: SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .dismissKeyboardOnTap()

                if !store.hidesTabBar {
                    LedgerTabBar(selected: $selected, items: tabs)
                }
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
