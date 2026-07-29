import SwiftUI

struct ReviewSessionView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var queue: [TrackedWord] = []
    @State private var revealed = false
    @State private var reviewed = 0

    var body: some View {
        NavigationStack {
            Group {
                if queue.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color("AppPrimary"))
                        Text(reviewed == 0 ? "Nothing due" : "Review complete")
                            .font(.system(.title3, design: .serif).weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                        Text(reviewed == 0
                             ? "New and due lexicon cards will appear here."
                             : "You reviewed \(reviewed) card\(reviewed == 1 ? "" : "s").")
                            .font(.system(.body, design: .serif))
                            .foregroundStyle(Color("AppTextSecondary"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                        Button("Done") { dismiss() }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let card = queue.first {
                    VStack(spacing: 18) {
                        Text("\(reviewed + 1) of \(reviewed + queue.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color("AppTextSecondary"))

                        SoftCard {
                            VStack(spacing: 14) {
                                Text(card.word)
                                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                                    .foregroundStyle(Color("AppTextPrimary"))
                                    .multilineTextAlignment(.center)
                                Text(card.bookTitle)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Color("AppAccent"))
                                if revealed {
                                    Divider().background(Color("AppTextSecondary").opacity(0.25))
                                    Text(card.definition)
                                        .font(.system(.body, design: .serif))
                                        .foregroundStyle(Color("AppTextSecondary"))
                                        .multilineTextAlignment(.center)
                                    if !card.notes.isEmpty {
                                        Text(card.notes)
                                            .font(.caption)
                                            .foregroundStyle(Color("AppTextSecondary"))
                                            .italic()
                                    }
                                } else {
                                    Text("Tap to reveal definition")
                                        .font(.subheadline)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                        .padding(.top, 8)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) { revealed = true }
                            HapticService.light()
                        }

                        if revealed {
                            HStack(spacing: 10) {
                                gradeButton(.forgot)
                                gradeButton(.almost)
                                gradeButton(.know)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(store.manuscriptTheme.colorScheme.swiftUI, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
            .screenBackground()
            .onAppear {
                queue = store.dueReviewWords
            }
        }
    }

    private func gradeButton(_ grade: ReviewGrade) -> some View {
        Button {
            guard let card = queue.first else { return }
            store.reviewWord(card, grade: grade)
            withAnimation(.easeInOut(duration: 0.2)) {
                _ = queue.removeFirst()
                reviewed += 1
                revealed = false
            }
        } label: {
            Text(grade.title)
                .font(.system(.subheadline, design: .serif).weight(.bold))
                .foregroundStyle(Color("AppBackground"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(gradeColor(grade))
                .overlay(
                    Rectangle()
                        .strokeBorder(Color("AppAccent").opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func gradeColor(_ grade: ReviewGrade) -> Color {
        switch grade {
        case .forgot: return Color.red.opacity(0.85)
        case .almost: return Color("AppAccent")
        case .know: return Color("AppPrimary")
        }
    }
}
