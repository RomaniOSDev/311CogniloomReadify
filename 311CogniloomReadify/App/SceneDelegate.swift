import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        let root = UIHostingController(rootView: ContentView())
        root.view.backgroundColor = UIColor(named: "AppBackground") ?? UIColor.black
        window.backgroundColor = UIColor(named: "AppBackground") ?? UIColor.black
        window.rootViewController = root
        self.window = window
        window.makeKeyAndVisible()
        handleIncomingURLs(connectionOptions.urlContexts)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        handleIncomingURLs(URLContexts)
    }

    private func handleIncomingURLs(_ contexts: Set<UIOpenURLContext>) {
        guard let url = contexts.first?.url,
              let text = DocumentTextLoader.load(from: url) else { return }
        AppDataStore.shared.ingestImportedText(text)
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
