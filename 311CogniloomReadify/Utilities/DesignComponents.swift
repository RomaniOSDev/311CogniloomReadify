import SwiftUI
import UIKit

// MARK: - Literary manuscript / ledger language (distinct from soft gradient cards)

struct LiteraryTitle: ViewModifier {
    var size: CGFloat = 28

    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: .bold, design: .serif))
            .foregroundStyle(Color("AppTextPrimary"))
    }
}

extension View {
    func literaryTitle(_ size: CGFloat = 28) -> some View {
        modifier(LiteraryTitle(size: size))
    }

    /// Hairline underline used under screen titles.
    func manuscriptUnderline() -> some View {
        overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color("AppPrimary").opacity(0.55))
                .frame(height: 2)
                .offset(y: 6)
        }
        .padding(.bottom, 8)
    }
}

/// Book-spine inspired card — left colored spine strip.
struct SpineCard<Content: View>: View {
    var spineColor: Color = Color("AppPrimary")
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [spineColor, Color("AppAccent")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 6)

            content()
                .padding(.vertical, 14)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color("AppSurface"))
        .overlay(
            Rectangle()
                .strokeBorder(Color("AppTextPrimary").opacity(0.18), lineWidth: 1)
        )
        .overlay(alignment: .top) {
            // Ruled-paper hairlines
            VStack(spacing: 18) {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle()
                        .fill(Color("AppTextSecondary").opacity(0.08))
                        .frame(height: 1)
                }
            }
            .padding(.top, 36)
            .padding(.leading, 18)
            .padding(.trailing, 10)
            .allowsHitTesting(false)
        }
        .shadow(color: Color.black.opacity(0.28), radius: 4, x: 2, y: 3)
    }
}

/// Flat manuscript panel — sharp corners, double rule, no soft pill look.
struct SoftCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .background(Color("AppSurface"))
            .overlay(
                Rectangle()
                    .strokeBorder(Color("AppAccent").opacity(0.35), lineWidth: 1)
                    .padding(3)
            )
            .overlay(
                Rectangle()
                    .strokeBorder(Color("AppTextPrimary").opacity(0.22), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 3, x: 1, y: 2)
    }
}

/// Ink stamp button — sharp corners, serif, solid fill (not soft gradient capsule).
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .serif).weight(.bold))
            .foregroundStyle(Color("AppBackground"))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            .frame(minHeight: 44)
            .frame(maxWidth: .infinity)
            .background(Color("AppPrimary"))
            .overlay(
                Rectangle()
                    .strokeBorder(Color("AppAccent"), lineWidth: 2)
                    .padding(3)
            )
            .shadow(color: Color.black.opacity(0.35), radius: configuration.isPressed ? 1 : 3, x: 1, y: configuration.isPressed ? 1 : 3)
            .offset(y: configuration.isPressed ? 1 : 0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct AchievementBanner: View {
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .strokeBorder(Color("AppPrimary"), lineWidth: 2)
                    .frame(width: 40, height: 40)
                Image(systemName: "bookmark.fill")
                    .foregroundStyle(Color("AppPrimary"))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Achievement Unlocked")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
                Text(title)
                    .font(.system(.subheadline, design: .serif).weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color("AppSurface"))
        .overlay(
            Rectangle()
                .strokeBorder(Color("AppPrimary").opacity(0.55), lineWidth: 1.5)
        )
        .padding(.horizontal, 16)
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    let actionTitle: String
    var action: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Rectangle()
                    .strokeBorder(Color("AppPrimary").opacity(0.45), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .frame(width: 96, height: 96)
                Image(systemName: symbol)
                    .font(.system(size: 40))
                    .foregroundStyle(Color("AppPrimary"))
            }
            Text(title)
                .font(.system(.title3, design: .serif).weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .manuscriptUnderline()
                .padding(.horizontal, 28)
            Text(message)
                .font(.system(.body, design: .serif))
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(actionTitle) {
                HapticService.light()
                action()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Custom ledger-style bottom rail (replaces system TabBar look).
struct LedgerTabBar: View {
    @Binding var selected: Int
    let items: [(title: String, icon: String)]
    @Namespace private var tabIndicator

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                Button {
                    HapticService.light()
                    withAnimation(.easeInOut(duration: 0.2)) { selected = index }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: items[index].icon)
                            .font(.system(size: 18, weight: .semibold))
                            .frame(height: 22)
                        Text(items[index].title)
                            .font(.system(size: 10, weight: .bold, design: .serif))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(selected == index ? Color("AppPrimary") : Color("AppTextSecondary"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .contentShape(Rectangle())
                    .background {
                        if selected == index {
                            Color("AppPrimary").opacity(0.12)
                        }
                    }
                    .overlay(alignment: .bottom) {
                        ZStack(alignment: .bottom) {
                            if selected == index {
                                Rectangle()
                                    .fill(Color("AppPrimary"))
                                    .frame(height: 2)
                                    .matchedGeometryEffect(id: "ledgerTabIndicator", in: tabIndicator)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 2)
                    }
                    .clipped()
                }
                .buttonStyle(.plain)
                if index < items.count - 1 {
                    Rectangle()
                        .fill(Color("AppTextSecondary").opacity(0.25))
                        .frame(width: 1, height: 28)
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 2)
        .frame(maxWidth: .infinity)
        .background {
            Color("AppSurface")
                .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color("AppTextPrimary").opacity(0.2))
                .frame(height: 1)
        }
        .shadow(color: .black.opacity(0.35), radius: 6, y: -2)
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        simultaneousGesture(
            TapGesture().onEnded {
                KeyboardSupport.dismiss()
            }
        )
    }

    func clearScrollBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.clear)
    }
}

struct BookCoverPlate: View {
    let book: ShelfBook

    var body: some View {
        ZStack {
            book.coverTint.color
            if let data = book.coverImageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [book.coverTint.color, book.coverTint.color.opacity(0.72)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                VStack(spacing: 8) {
                    Text(String(book.title.prefix(1)).uppercased())
                        .font(.system(size: 28, weight: .bold, design: .serif))
                    Text(book.title)
                        .font(.system(size: 12, weight: .semibold, design: .serif))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 8)
                }
                .foregroundStyle(Color.white.opacity(0.92))
            }
        }
        .aspectRatio(0.68, contentMode: .fit)
        .clipped()
        .overlay(
            Rectangle()
                .strokeBorder(Color("AppTextPrimary").opacity(0.28), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 4, x: 2, y: 3)
    }
}

struct HighlightedPassageText: View {
    let passage: String
    let wordRange: NSRange

    var body: some View {
        Text(attributed)
            .font(.system(.body, design: .serif))
            .foregroundStyle(Color("AppTextPrimary"))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var attributed: AttributedString {
        var result = AttributedString(passage)
        guard
            let stringRange = Range(wordRange, in: passage),
            let attrRange = Range(stringRange, in: result)
        else { return result }
        result[attrRange].backgroundColor = Color("AppAccent").opacity(0.35)
        result[attrRange].foregroundColor = Color("AppTextPrimary")
        result[attrRange].underlineStyle = .single
        return result
    }
}

struct SittingChip: View {
    let session: ReadingSession

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "timer")
            Text(Self.clock(session.remainingSeconds))
                .monospacedDigit()
            Text("·")
            Text("\(session.quotesCaptured)/\(session.quoteGoal)")
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(Color("AppBackground"))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color("AppPrimary"))
        .overlay(
            Rectangle()
                .strokeBorder(Color("AppAccent"), lineWidth: 1)
                .padding(2)
        )
    }

    static func clock(_ seconds: Int) -> String {
        let m = max(0, seconds) / 60
        let s = max(0, seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}

/// Tap a word inside a passage. Uses the system text tokenizer so punctuation stays out of the word.
struct TappablePassageView: UIViewRepresentable {
    let text: String
    var highlightRanges: [NSRange] = []
    var onWord: (String, NSRange) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onWord: onWord)
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        view.isEditable = false
        view.isSelectable = false
        view.isScrollEnabled = true
        view.backgroundColor = .clear
        view.textContainerInset = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
        view.textContainer.lineFragmentPadding = 0
        view.adjustsFontForContentSizeCategory = true
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)
        context.coordinator.textView = view
        applyText(to: view)
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.onWord = onWord
        if uiView.attributedText?.string != text {
            applyText(to: uiView)
        } else {
            applyHighlights(to: uiView)
        }
    }

    private func applyText(to view: UITextView) {
        view.attributedText = makeAttributed()
    }

    private func applyHighlights(to view: UITextView) {
        view.attributedText = makeAttributed()
    }

    private func makeAttributed() -> NSAttributedString {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let serif = font.fontDescriptor.withDesign(.serif).map { UIFont(descriptor: $0, size: font.pointSize) } ?? font
        let color = UIColor(named: "AppTextPrimary") ?? .label
        let storage = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: serif,
                .foregroundColor: color
            ]
        )
        let accent = UIColor(named: "AppAccent") ?? .systemOrange
        for range in highlightRanges where NSMaxRange(range) <= storage.length {
            storage.addAttributes([
                .backgroundColor: accent.withAlphaComponent(0.32),
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ], range: range)
        }
        return storage
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var onWord: (String, NSRange) -> Void
        weak var textView: UITextView?

        init(onWord: @escaping (String, NSRange) -> Void) {
            self.onWord = onWord
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let textView else { return }
            let point = gesture.location(in: textView)
            guard let position = textView.closestPosition(to: point) else { return }
            guard let range = textView.tokenizer.rangeEnclosingPosition(
                position,
                with: .word,
                inDirection: UITextDirection(rawValue: UITextLayoutDirection.right.rawValue)
            ) ?? textView.tokenizer.rangeEnclosingPosition(
                position,
                with: .word,
                inDirection: UITextDirection(rawValue: UITextLayoutDirection.left.rawValue)
            ) else { return }
            guard let word = textView.text(in: range) else { return }
            let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count > 1, trimmed.contains(where: \.isLetter) else { return }
            let location = textView.offset(from: textView.beginningOfDocument, to: range.start)
            let length = textView.offset(from: range.start, to: range.end)
            HapticService.light()
            onWord(trimmed, NSRange(location: location, length: length))
        }
    }
}
