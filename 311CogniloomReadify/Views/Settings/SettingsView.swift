import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showResetAlert = false
    @State private var soundEnabled = HapticService.soundEnabled
    @State private var hapticsEnabled = HapticService.hapticsEnabled
    @State private var reminderDate = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    NavigationLink {
                        StatisticsView()
                    } label: {
                        SoftCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Stats")
                                        .font(.system(.headline, design: .serif))
                                        .foregroundStyle(Color("AppTextPrimary"))
                                    Spacer()
                                    Text("Charts")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color("AppPrimary"))
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                                HStack {
                                    statCell("Words", "\(store.stats.itemsCreated)")
                                    statCell("Sessions", "\(store.stats.sessionsCompleted)")
                                    statCell("Streak", "\(store.stats.streakDays)")
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded {
                        HapticService.light()
                    })

                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Daily goal")
                                .font(.system(.headline, design: .serif))
                                .foregroundStyle(Color("AppTextPrimary"))
                            Stepper(value: Binding(
                                get: { store.dailyGoal },
                                set: { store.setDailyGoal($0) }
                            ), in: 1...30) {
                                Text("\(store.dailyGoal) word\(store.dailyGoal == 1 ? "" : "s") / day")
                                    .foregroundStyle(Color("AppTextPrimary"))
                            }
                            .tint(Color("AppPrimary"))

                            Toggle(isOn: Binding(
                                get: { store.reminderEnabled },
                                set: { store.setReminderEnabled($0) }
                            )) {
                                Label {
                                    Text("Daily reminder")
                                        .foregroundStyle(Color("AppTextPrimary"))
                                } icon: {
                                    Image(systemName: "bell.fill")
                                        .foregroundStyle(Color("AppPrimary"))
                                        .frame(width: 28)
                                }
                            }
                            .tint(Color("AppPrimary"))

                            if store.reminderEnabled {
                                DatePicker(
                                    "Reminder time",
                                    selection: $reminderDate,
                                    displayedComponents: .hourAndMinute
                                )
                                .tint(Color("AppPrimary"))
                                .onChange(of: reminderDate) { value in
                                    let comps = Calendar.current.dateComponents([.hour, .minute], from: value)
                                    store.setReminderTime(hour: comps.hour ?? 20, minute: comps.minute ?? 0)
                                }
                            }

                            HStack(spacing: 8) {
                                Image(systemName: store.streakProtectionAvailable ? "shield.lefthalf.filled" : "shield.fill")
                                    .foregroundStyle(Color("AppAccent"))
                                Text(store.streakProtectionAvailable
                                     ? "Streak shield available (1 missed day / week)."
                                     : "Streak shield already used this week.")
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Look")
                                .font(.system(.headline, design: .serif))
                                .foregroundStyle(Color("AppTextPrimary"))
                            ForEach(ManuscriptTheme.allCases) { theme in
                                Button {
                                    store.setManuscriptTheme(theme)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: store.manuscriptTheme == theme ? "circle.inset.filled" : "circle")
                                            .foregroundStyle(Color("AppPrimary"))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(theme.title)
                                                .foregroundStyle(Color("AppTextPrimary"))
                                            Text(theme.detail)
                                                .font(.caption)
                                                .foregroundStyle(Color("AppTextSecondary"))
                                        }
                                        Spacer()
                                    }
                                    .frame(minHeight: 44)
                                }
                                .buttonStyle(.plain)
                                if theme != ManuscriptTheme.allCases.last {
                                    Divider().background(Color("AppTextSecondary").opacity(0.25))
                                }
                            }
                        }
                    }

                    SoftCard {
                        VStack(spacing: 0) {
                            Toggle(isOn: $soundEnabled) {
                                Label {
                                    Text("Sound Effects")
                                        .foregroundStyle(Color("AppTextPrimary"))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                } icon: {
                                    Image(systemName: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                        .foregroundStyle(Color("AppPrimary"))
                                        .frame(width: 28)
                                }
                            }
                            .tint(Color("AppPrimary"))
                            .frame(minHeight: 44)
                            .padding(.vertical, 6)
                            .onChange(of: soundEnabled) { value in
                                HapticService.soundEnabled = value
                                if value { HapticService.play(1104) }
                            }

                            Divider().background(Color("AppTextSecondary").opacity(0.25))

                            Toggle(isOn: $hapticsEnabled) {
                                Label {
                                    Text("Haptic Feedback")
                                        .foregroundStyle(Color("AppTextPrimary"))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                } icon: {
                                    Image(systemName: "hand.tap.fill")
                                        .foregroundStyle(Color("AppPrimary"))
                                        .frame(width: 28)
                                }
                            }
                            .tint(Color("AppPrimary"))
                            .frame(minHeight: 44)
                            .padding(.vertical, 6)
                            .onChange(of: hapticsEnabled) { value in
                                HapticService.hapticsEnabled = value
                                if value { HapticService.light() }
                            }
                        }
                    }

                    SoftCard {
                        VStack(spacing: 0) {
                            settingsButton(title: "Rate Us", systemImage: "star.fill") {
                                rateApp()
                            }
                            Divider().background(Color("AppTextSecondary").opacity(0.25))
                            settingsButton(title: "Privacy Policy", systemImage: "hand.raised.fill") {
                                openURL(AppLinks.privacyPolicy)
                            }
                            Divider().background(Color("AppTextSecondary").opacity(0.25))
                            settingsButton(title: "Terms of Use", systemImage: "doc.text.fill") {
                                openURL(AppLinks.termsOfUse)
                            }
                        }
                    }

                    Button {
                        HapticService.warning()
                        showResetAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Reset All Data")
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer()
                        }
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(Color.red.opacity(0.95))
                        .padding(16)
                        .background(Color("AppSurface"))
                        .overlay(
                            Rectangle()
                                .strokeBorder(Color.red.opacity(0.55), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 24)
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("Prefs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(store.manuscriptTheme.colorScheme.swiftUI, for: .navigationBar)
            .screenBackground()
            .dismissKeyboardOnTap()
            .onAppear {
                soundEnabled = HapticService.soundEnabled
                hapticsEnabled = HapticService.hapticsEnabled
                var comps = DateComponents()
                comps.hour = store.reminderHour
                comps.minute = store.reminderMinute
                reminderDate = Calendar.current.date(from: comps) ?? Date()
            }
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    store.resetAll()
                }
            } message: {
                Text("This clears tracked words, organized vocabulary, book insights, and achievements on this device.")
            }
        }
    }

    private func statCell(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
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

    private func settingsButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticService.light()
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundStyle(Color("AppPrimary"))
                    .frame(width: 28)
                Text(title)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .frame(minHeight: 44)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
