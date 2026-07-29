import SwiftUI

struct QuizView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var questions: [QuizQuestion] = []
    @State private var index = 0
    @State private var score = 0
    @State private var selected: String?
    @State private var finished = false

    var body: some View {
        NavigationStack {
            Group {
                if finished {
                    resultBody
                } else if questions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "questionmark.square.dashed")
                            .font(.system(size: 48))
                            .foregroundStyle(Color("AppTextSecondary"))
                        Text("Need more words")
                            .font(.system(.title3, design: .serif).weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                        Text("Add at least two lexicon words with definitions to start a quiz.")
                            .font(.system(.body, design: .serif))
                            .foregroundStyle(Color("AppTextSecondary"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                        Button("Close") { dismiss() }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    quizBody
                }
            }
            .navigationTitle("Quiz")
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
                questions = store.makeQuizQuestions(count: 8)
            }
        }
    }

    private var quizBody: some View {
        let q = questions[index]
        return VStack(alignment: .leading, spacing: 16) {
            Text("Question \(index + 1)/\(questions.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("AppTextSecondary"))
            SoftCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("What does this word mean?")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                    Text(q.word)
                        .font(.system(.title, design: .serif).weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                }
            }
            ForEach(q.options, id: \.self) { option in
                Button {
                    guard selected == nil else { return }
                    selected = option
                    if option == q.correct {
                        score += 1
                        HapticService.success()
                    } else {
                        HapticService.warning()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                        advance()
                    }
                } label: {
                    Text(option)
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(optionBackground(option, correct: q.correct))
                        .overlay(
                            Rectangle()
                                .strokeBorder(Color("AppTextPrimary").opacity(0.18), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(selected != nil)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
    }

    private var resultBody: some View {
        VStack(spacing: 18) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color("AppPrimary"))
            Text("Quiz finished")
                .font(.system(.title3, design: .serif).weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))
            Text("\(score)/\(questions.count) correct")
                .font(.system(.title2, design: .serif).weight(.bold))
                .foregroundStyle(Color("AppAccent"))
            Button("Try again") {
                questions = store.makeQuizQuestions(count: 8)
                index = 0
                score = 0
                selected = nil
                finished = false
                HapticService.light()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)
            Button("Done") { dismiss() }
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func optionBackground(_ option: String, correct: String) -> Color {
        guard let selected else { return Color("AppSurface") }
        if option == correct { return Color("AppPrimary").opacity(0.35) }
        if option == selected { return Color.red.opacity(0.28) }
        return Color("AppSurface")
    }

    private func advance() {
        if index + 1 >= questions.count {
            finished = true
            store.flashSuccess()
        } else {
            index += 1
            selected = nil
        }
    }
}
