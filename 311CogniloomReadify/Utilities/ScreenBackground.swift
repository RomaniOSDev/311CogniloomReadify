import SwiftUI

struct ScreenBackground: ViewModifier {
    @EnvironmentObject private var store: AppDataStore
    var imageName: String = "img_background"
    var opacityOverride: Double?

    func body(content: Content) -> some View {
        let theme = store.manuscriptTheme
        let opacity = opacityOverride ?? theme.backgroundOpacity
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color("AppBackground")
                    .overlay {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .opacity(opacity)
                    }
                    .overlay {
                        if theme.usesSepiaWash {
                            Color(red: 0.55, green: 0.38, blue: 0.18).opacity(0.16)
                        }
                    }
                    .overlay {
                        ManuscriptRuling()
                            .opacity(theme == .parchment ? 0.18 : 0.10)
                    }
                    .clipped()
                    .ignoresSafeArea()
            }
    }
}

private struct ManuscriptRuling: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let line = Color("AppTextPrimary")
                var y: CGFloat = 28
                while y < size.height {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path, with: .color(line), lineWidth: 0.6)
                    y += 22
                }
                var margin = Path()
                margin.move(to: CGPoint(x: 28, y: 0))
                margin.addLine(to: CGPoint(x: 28, y: size.height))
                context.stroke(margin, with: .color(Color("AppAccent")), lineWidth: 1)
            }
            .allowsHitTesting(false)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

extension View {
    func screenBackground(_ imageName: String = "img_background", opacity: Double? = nil) -> some View {
        modifier(ScreenBackground(imageName: imageName, opacityOverride: opacity))
    }
}
