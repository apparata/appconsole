//
//  Copyright © 2018 Apparata AB. All rights reserved.
//

import Foundation
import UIKit

class AppNavigationController {
    
    var tabBarController: UITabBarController?
    
    init() {
        observeCommands()
    }

    func observeCommands() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleCommandNotification(_:)), name: Notification.Name(rawValue: "appconsole.command"), object: nil)
    }
    
    @objc func handleCommandNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let client = userInfo["client"],
            let commands = userInfo["commands"] as? [String] else {
                return
        }
        let arguments = userInfo["arguments"] as? [String: Any] ?? [String: Any]()
        handleCommand(client: client, commands: commands, arguments: arguments)
    }
    
    func handleCommand(client: Any, commands: [String], arguments: [String: Any]) {
        switch commands {
        case ["selectTab"]:
            if let tabIndex = arguments["index"] as? Int {
                DispatchQueue.main.async { [tabBarController] in
                    if tabIndex >= 0 && tabIndex < tabBarController?.viewControllers?.count ?? 0 {
                        tabBarController?.selectedIndex = tabIndex
                    }
                }
            }
            
        case ["shake"]:
            DispatchQueue.main.async { [weak self] in
                if let view = self?.tabBarController?.view {
                    self?.shakeHorizontally(layer: view.layer)
                }
            }
                
        default:
            return
        }

    }
    
    public func shakeHorizontally(layer: CALayer) {
        let shake = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shake.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        shake.duration = 0.5
        shake.beginTime = CACurrentMediaTime()
        shake.values = [-20, 20, -20, 20, -10, 10, -5, 5, 0]
        layer.add(shake, forKey: "shake")
    }
    
}
