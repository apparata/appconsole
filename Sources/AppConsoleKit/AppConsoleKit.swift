
import Foundation
import Cocoa
import Approach

public class AppConsole: NSObject {
    
    private let instanceName: String
    private var messageClient: MessageClient!
    private var lineEditor: LineEditor?
    private var commands: [Command] = []
    private let verbose: Bool
    
    public init(instanceName: String, verbose: Bool) {
        self.instanceName = instanceName
        self.verbose = verbose
    }
    
    public func start() {
        messageClient = MessageClient(serviceName: instanceName)

        if verbose {
            MessageClient.log = { _, string in
                print("[MessageClient] \(string)")
            }
        }
            
        messageClient.delegate = self
        
        messageClient.connect()
    }
    
    public func stop() {
        lineEditor?.destroy()
        lineEditor = nil
    }
    
    private func printCommandList() {
        Console.print("\nThese commands are available:\n")
        let maxCommandLength = commands.reduce(0) { return max($0, $1.name.count) }
        for command in commands {
            let paddedName = command.name.padding(toLength: maxCommandLength, withPad: " ", startingAt: 0)
            Console.print("<bold>\(paddedName)</bold>\t\(command.description)")
        }
        Console.print("")
    }
}

extension AppConsole: MessageClientDelegate {
    
    public func clientDidStartSession(_ client: MessageClient) {
        commands = []
        Console.print("\n*** Session started.")
    }
    
    public func clientDidEndSession(_ client: MessageClient) {
        Console.print("\n\n*** Session ended. Waiting for new session.")
        commands = []
        client.connect()
    }
    
    public func client(_ client: MessageClient, didReceiveMessage data: Data, metadata: Data) {
        let messageMetadata = try! JSONDecoder().decode(AppConsoleMessageMetadata.self, from: metadata)
        
        switch messageMetadata.messageType {
            
        case .generalInfo:
            handleGeneralInfo(data, from: client)
            
        case .commandsSpecification:
            handleCommandsSpecification(data, from: client)
            
        case .readyForCommand:
            readNextCommand()
            
        case .consoleOutput:
            handleConsoleOutput(data, from: client)
            
        case .screenshot:
            handleScreenshot(data, from: client)
            
        case .file:
            handleFile(data, from: client)
            
        default:
            break
        }
    }
    
    func handleGeneralInfo(_ data: Data, from client: MessageClient) {
        
        let info = try! JSONDecoder().decode(AppConsoleInfo.self, from: data)
        
        if commands.isEmpty {
            Console.print("""

     <bold><blue><underline>Device Info</underline></blue></bold>
      Name: \(info.device.name.replacingOccurrences(of: "&", with: "&amp;"))
     Model: \(info.device.model) (\(DeviceType(identifier: info.device.identifier)))
 Simulator: \(info.device.isSimulator ? "Yes" : "No")
   Battery: \(max(0, info.device.batteryLevel * 100.0))

     <bold><blue><underline>System Info</underline></blue></bold>
    System: \(info.system.name) \(info.system.version)
    Locale: \(info.system.locale)
  Language: \(info.system.language)
 Preferred: \(info.system.preferredLanguages.joined(separator: ", "))
                
        <bold><blue><underline>App Info</underline></blue></bold>
      Name: \(info.app.name.replacingOccurrences(of: "&", with: "&amp;"))
 Bundle ID: \(info.app.bundleID)
   Version: \(info.app.version) (\(info.app.buildVersion))
""")
            
            sendListCommands(client: client)
        }
    }
    
    func handleCommandsSpecification(_ data: Data, from client: MessageClient) {
        let commandsSpecification = try! JSONDecoder().decode(CommandsSpecification.self, from: data)
        commands = commandsSpecification.commands + [Self.makeHelpCommand()]
        Console.print("\nType 'help' to list available commands.")
    }
    
    func handleConsoleOutput(_ data: Data, from client: MessageClient) {
        guard let output = String(data: data, encoding: .utf8) else {
            return
        }
        Console.print("")
        Console.print(output)
        fflush(stdout)
    }
    
    func handleScreenshot(_ data: Data, from client: MessageClient) {
        let url = URL(fileURLWithPath: "/tmp/appconsole-screenshot.png")
        try? data.write(to: url, options: .atomic)
        NSWorkspace.shared.open(url)
    }
    
    func handleFile(_ data: Data, from client: MessageClient) {
        let fileInfo = try! JSONDecoder().decode(RemoteFileInfo.self, from: data)
        let url = URL(fileURLWithPath: "/tmp/\(fileInfo.filename)")
        try? fileInfo.filedata.write(to: url, options: .atomic)
        NSWorkspace.shared.open(url)
    }
    
    private static func makeHelpCommand() -> Command {
        let arguments: [Argument] = [
            Input("command", type: .string, isOptional: true, description: "Command to display help text for.")
        ]
        
        let commandDefinition = Command(name: "help",
                                        description: "Use 'help &lt;command&gt;' to display help text for command.",
                                        arguments: arguments)
        return commandDefinition
    }
    
    private func sendListCommands(client: MessageClient) {
        messageClient.sendMessage(.listCommands)
    }
    
    private func readNextCommand() {
        if let lineEditor = lineEditor {
            lineEditor.reset()
        } else {
            lineEditor = LineEditor()
        }
        DispatchQueue(label: "appconsole.repl").async { [weak self] in
            self?.readNextCommandOnREPLThread()
        }
    }
    
    private func readNextCommandOnREPLThread() {

        guard let line = lineEditor?.readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            Console.print("\n")
            exit(0)
        }
        
        if line.isEmpty {
            readNextCommand()
            return
        }
        
        let commandLineProcessor = CommandLineProcessor()
        guard commands.count > 0 else {
            Console.print("Error: There are no commands.")
            readNextCommand()
            return
        }
        if line == "help" {
            printCommandList()
            readNextCommand()
            return
        }
        do {
            let parsedCommand = try commandLineProcessor.evaluate(line, commands: commands)
            messageClient.sendMessage(.executeCommand, parsedCommand)
        } catch {
            Console.print("\(error.localizedDescription)")
            readNextCommand()
        }
    }
}

public extension MessageClient {
    
    func sendMessage<T: Encodable>(_ type: AppConsoleMessageType,
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
            completion?(.failure(error))
        }
    }
    
    func sendMessage(_ type: AppConsoleMessageType, completion: ((SendMessageResult) -> Void)? = nil) {
        let encoder = JSONEncoder()
        do {
            let metadata = try encoder.encode(AppConsoleMessageMetadata(type))
            sendMessage(data: Data(), metadata: metadata, completion: completion)
        } catch {
            completion?(.failure(error))
        }
    }
}

