//
//  Copyright © 2018 Apparata AB. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var appNavigationController = AppNavigationController()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        setUpUI()
        
        AppConsoleService.shared.start()

        return true
    }
    
    // MARK: - Setup
    
    private func setUpUI() {
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarController = storyboard.instantiateInitialViewController() as! UITabBarController
        window.rootViewController = tabBarController
        appNavigationController.tabBarController = tabBarController
        window.makeKeyAndVisible()
    }
    
    // MARK: - App Lifecycle
    
    func applicationWillResignActive(_ application: UIApplication) {}
    func applicationDidEnterBackground(_ application: UIApplication) {}
    func applicationWillEnterForeground(_ application: UIApplication) {}
    func applicationDidBecomeActive(_ application: UIApplication) {}
    func applicationWillTerminate(_ application: UIApplication) {}
}

