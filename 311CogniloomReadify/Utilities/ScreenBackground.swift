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
                    .clipped()
                    .ignoresSafeArea()
            }
    }
}

extension View {
    func screenBackground(_ imageName: String = "img_background", opacity: Double? = nil) -> some View {
        modifier(ScreenBackground(imageName: imageName, opacityOverride: opacity))
    }
}
