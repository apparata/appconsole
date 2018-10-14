//
//  Copyright © 2018 Apparata AB. All rights reserved.
//

import UIKit

class PhotoViewController: UIViewController {
    
    @IBOutlet weak var photoImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        case ["upload"]:
            if let photoData = arguments["photo"] as? Data {
                if let image = UIImage(data: photoData) {
                    DispatchQueue.main.async { [photoImageView] in
                        photoImageView?.image = image
                    }

                }
            }
            
        default:
            return
        }
        
    }
    
}
