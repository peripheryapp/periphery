import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        print(MultiTargetStruct.usedInApp)
        print(MultiTargetStruct.usedInBoth)

        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)

        // Create a tab bar controller to navigate between different XIB/storyboard view controllers
        let tabBarController = UITabBarController()

        // Tab 1: XibViewController (from XIB)
        let xibVC = XibViewController(nibName: "XibViewController", bundle: nil)
        xibVC.tabBarItem = UITabBarItem(title: "XIB", image: UIImage(systemName: "1.circle"), tag: 0)

        // Tab 2: StoryboardViewController (from storyboard)
        let storyboard = UIStoryboard(name: "StoryboardViewController", bundle: nil)
        let storyboardVC = storyboard.instantiateInitialViewController() ?? StoryboardViewController()
        storyboardVC.tabBarItem = UITabBarItem(title: "Storyboard", image: UIImage(systemName: "2.circle"), tag: 1)

        // Tab 3: XibViewController2Subclass (tests inherited IBAction)
        let xibVC2 = XibViewController2Subclass(nibName: "XibViewController2Subclass", bundle: nil)
        xibVC2.tabBarItem = UITabBarItem(title: "Subclass", image: UIImage(systemName: "3.circle"), tag: 2)

        tabBarController.viewControllers = [xibVC, storyboardVC, xibVC2]

        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        self.window = window
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
