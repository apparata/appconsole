//
//  Copyright © 2018 Apparata AB. All rights reserved.
//

import Foundation
import UIKit
import AudioToolbox

class AppConsoleService {
    
    static let shared = AppConsoleService()
    
    let commands = AppConsoleCommands.makeCommands()
    
    var messageService: MessageService!
    
    init() {
        
    }
    
    func start() {
        MessageService.log = { _, string in
            print("[MessageService] \(string)")
        }
        RemoteMessageClient.log = { _, string in
            print("[RemoteMessageClient] \(string)")
        }
        
        messageService = try! MessageService(name: "MyApp")
        messageService.delegate = self
        messageService.start()
    }
}

extension AppConsoleService: MessageServiceDelegate {
    func messageService(_ service: MessageService, clientDidConnect client: RemoteMessageClient) {
        client.delegate = self
    }
}

extension AppConsoleService: RemoteMessageClientDelegate {
    
    func clientDidStartSession(_ client: RemoteMessageClient) {
        client.sendMessage(.generalInfo, AppConsoleInfo())
    }
    
    func client(_ client: RemoteMessageClient, didReceiveMessage data: Data, metadata: Data) {
        
        let messageMetadata = try! JSONDecoder().decode(AppConsoleMessageMetadata.self, from: metadata)
        
        switch messageMetadata.messageType {
            
        case .listCommands:
            handleListCommands(from: client)
            
        case .executeCommand:
            handleExecuteCommand(data, from: client)
            
        default:
            break
        }
    }
    
    func handleListCommands(from client: RemoteMessageClient) {
        client.sendMessage(.commandsSpecification, CommandsSpecification(commands: commands))
        client.sendMessage(.readyForCommand)
    }
    
    func handleExecuteCommand(_ commandData: Data, from client: RemoteMessageClient) {
        guard let command = try? JSONDecoder().decode(AppCommand.self, from: commandData) else {
            print("Error: Failed to decode command object.")
            return
        }
        
        switch command.commands {
        case ["vibrate"]:
            handleVibrateCommand(command, from: client)
        case ["screenshot"]:
            handleScreenshotCommand(command, from: client)
        default:
            dump(command)
            sendConsoleOutput("Executed command.", to: client)
            postCommandNotification(command, from: client)
            client.sendMessage(.readyForCommand)
        }
    }
    
    func sendConsoleOutput(_ output: String, to client: RemoteMessageClient) {
        client.sendMessage(.consoleOutput, output)
    }
    
    func postCommandNotification(_ command: AppCommand, from client: RemoteMessageClient) {
        let name = Notification.Name(rawValue: "appconsole.command")
        NotificationCenter.default.post(name: name, object: self, userInfo: [
            "client": client,
            "commands": command.commands,
            "arguments": command.arguments.mapValues { (argument) -> Any in
                switch argument.value {
                case .bool(let value): return value
                case .int(let value): return value
                case .double(let value): return value
                case .string(let value): return value
                case .date(let value): return value
                case .file(let value): return value
                }
            }
        ])
    }
}

extension AppConsoleService {
    
    func handleVibrateCommand(_ command: AppCommand, from client: RemoteMessageClient) {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        sendConsoleOutput("Vibrated", to: client)
        client.sendMessage(.readyForCommand)
    }

    func handleScreenshotCommand(_ command: AppCommand, from client: RemoteMessageClient) {
        sendConsoleOutput("Taking screenshot.", to: client)
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate,
                let optionalWindow = appDelegate.window,
                let window = optionalWindow {
                
                UIGraphicsBeginImageContextWithOptions(window.bounds.size, false, UIScreen.main.scale)
                window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()

                if let screenshotData = image?.pngData() {
                    client.sendMessage(.screenshot, screenshotData)
                }
                
                client.sendMessage(.readyForCommand)
            }
        }
    }

}

public extension RemoteMessageClient {
    
    public func sendMessage<T: Encodable>(_ type: AppConsoleMessageType,
                                          _ payload: T,
                                          completion: ((SendMessageResult) -> Void)? = nil) {
        let encoder = JSONEncoder()
        do {
            let metadata = try encoder.encode(AppConsoleMessageMetadata(type))
            let data: Data
            if let string = payload as? String {
                data = string.data(using: .utf8) ?? Data()
            } else if let payloadData = payload as? Data {
                data = payloadData
            } else {
                data = try encoder.encode(payload)
            }
            sendMessage(data: data, metadata: metadata, completion: completion)
        } catch {
            print(error)
            completion?(.failure(error))
        }
    }
    
    public func sendMessage(_ type: AppConsoleMessageType, completion: ((SendMessageResult) -> Void)? = nil) {
        let encoder = JSONEncoder()
        do {
            let metadata = try encoder.encode(AppConsoleMessageMetadata(type))
            sendMessage(data: Data(), metadata: metadata, completion: completion)
        } catch {
            completion?(.failure(error))
        }
    }
}
