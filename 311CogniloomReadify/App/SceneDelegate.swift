import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var launchFlowResolver: LaunchFlowResolver?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        launchFlowResolver = LaunchFlowResolver(window: window)
        window?.rootViewController = launchFlowResolver?.resolveEntryViewController()
        window?.makeKeyAndVisible()
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
