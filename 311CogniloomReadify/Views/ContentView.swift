import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppDataStore.shared

    var body: some View {
        Group {
            if store.hasSeenOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(store.manuscriptTheme.colorScheme.swiftUI)
        .environmentObject(store)
        .onAppear {
            HapticService.prepare()
            KeyboardSupport.warmUp()
            if store.reminderEnabled {
                NotificationService.shared.syncReminder(
                    enabled: true,
                    hour: store.reminderHour,
                    minute: store.reminderMinute,
                    goal: store.dailyGoal
                )
            }
        }
    }
}
