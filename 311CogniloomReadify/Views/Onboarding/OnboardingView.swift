import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var page = 0
    @State private var appearScale: CGFloat = 0.7
    @State private var appearOpacity: Double = 0

    private let pages: [(title: String, body: String, symbol: String, image: String)] = [
        (
            "Expand Your Vocabulary",
            "Discover how this app helps you enrich your language skills through your readings.",
            "text.book.closed.fill",
            "img_banner"
        ),
        (
            "Log Unique Words",
            "Tap on any word in your book to capture its meaning and usage.",
            "pencil.and.outline",
            "img_card"
        ),
        (
            "Start Logging Now",
            "Begin by adding your first set of interesting words from your current book.",
            "bookmark.fill",
            "img_accent"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    onboardingPage(pages[index], index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: page)

            HStack(spacing: 10) {
                ForEach(pages.indices, id: \.self) { index in
                    Text(String(format: "%02d", index + 1))
                        .font(.system(size: 11, weight: .bold, design: .serif))
                        .foregroundStyle(index == page ? Color("AppBackground") : Color("AppTextSecondary"))
                        .frame(width: 28, height: 28)
                        .background(index == page ? Color("AppPrimary") : Color.clear)
                        .overlay(
                            Rectangle()
                                .strokeBorder(
                                    index == page ? Color("AppAccent") : Color("AppTextSecondary").opacity(0.45),
                                    lineWidth: 1
                                )
                        )
                        .animation(.easeInOut(duration: 0.2), value: page)
                }
            }
            .padding(.bottom, 18)

            Button {
                HapticService.light()
                if page < pages.count - 1 {
                    withAnimation(.easeInOut(duration: 0.3)) { page += 1 }
                } else {
                    store.completeOnboarding()
                }
            } label: {
                Text(page < pages.count - 1 ? "Next" : "Get Started")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .screenBackground(opacity: 0.22)
        .onChange(of: page) { _ in
            appearScale = 0.7
            appearOpacity = 0
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appearScale = 1
                appearOpacity = 1
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appearScale = 1
                appearOpacity = 1
            }
        }
    }

    private func onboardingPage(
        _ item: (title: String, body: String, symbol: String, image: String),
        index: Int
    ) -> some View {
        VStack(spacing: 26) {
            Spacer(minLength: 20)

            ZStack {
                Image(item.image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scaleEffect(index == page ? appearScale : 0.92)
                    .opacity(index == page ? appearOpacity : 0.65)

                LinearGradient(
                    colors: [
                        Color("AppBackground").opacity(0.2),
                        Color("AppBackground").opacity(0.65)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Image(systemName: item.symbol)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Color("AppPrimary"))
                    .padding(18)
                    .background(Color("AppBackground").opacity(0.8))
                    .overlay(
                        Rectangle()
                            .strokeBorder(Color("AppPrimary"), lineWidth: 1.5)
                    )
                    .scaleEffect(index == page ? appearScale : 0.85)
                    .opacity(index == page ? appearOpacity : 0.5)
            }
            .frame(height: 250)
            .clipShape(Rectangle())
            .overlay(
                Rectangle()
                    .strokeBorder(Color("AppTextPrimary").opacity(0.25), lineWidth: 1)
                    .padding(5)
            )
            .overlay(
                Rectangle()
                    .strokeBorder(Color("AppAccent").opacity(0.45), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.35), radius: 4, x: 2, y: 3)
            .padding(.horizontal, 28)

            VStack(spacing: 12) {
                Text(item.title)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .manuscriptUnderline()
                Text(item.body)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 28)
            }

            Spacer()
        }
    }
}
