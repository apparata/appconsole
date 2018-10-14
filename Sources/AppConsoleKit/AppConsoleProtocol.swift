
import Foundation
#if canImport(UIKit)
import UIKit
#endif

public enum AppConsoleMessageType: String, Codable {
    
    // Sent by client
    case listCommands
    case executeCommand
    
    // Sent by service
    case generalInfo
    case commandsSpecification
    case consoleOutput
    case screenshot
    case readyForCommand
}

public struct AppConsoleMessageMetadata: Codable {
    
    public let messageType: AppConsoleMessageType
    
    public static func encoded(_ messageType: AppConsoleMessageType) -> Data {
        return try! JSONEncoder().encode(AppConsoleMessageMetadata(messageType))
    }
    
    public init(_ messageType: AppConsoleMessageType) {
        self.messageType = messageType
    }
}

public struct AppConsoleInfo: Codable {
    
    public struct DeviceInfo: Codable {
        public let name: String
        public let model: String
        public let identifier: String
        public let localizedModel: String
        public let isSimulator: Bool
        public let batteryLevel: Float
        
        #if canImport(UIKit)
        init() {
            let device = UIDevice.current
            name = device.name
            model = device.model
            var systemInfo = utsname()
            uname(&systemInfo)
            let machineMirror = Mirror(reflecting: systemInfo.machine)
            identifier = machineMirror.children.reduce("") { identifier, element in
                guard let value = element.value as? Int8, value != 0 else { return identifier }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
            localizedModel = device.localizedModel
            #if targetEnvironment(simulator)
            isSimulator = true
            #else
            isSimulator = false
            #endif
            batteryLevel = device.batteryLevel
        }
        #endif
    }
    
    public struct SystemInfo: Codable {
        public let name: String
        public let version: String
        public let locale: String
        public let language: String
        public let preferredLanguages: [String]
        
        #if canImport(UIKit)
        init() {
            let device = UIDevice.current
            name = device.systemName
            version = device.systemVersion
            locale = Locale.current.identifier
            language = Locale.preferredLanguages[0]
            preferredLanguages = Locale.preferredLanguages
        }
        #endif
    }
    
    public struct AppInfo: Codable {
        public let name: String
        public let bundleID: String
        public let version: String
        public let buildVersion: String
        public let isTestFlight: Bool
        
        #if canImport(UIKit)
        init() {
            let info = Bundle.main.infoDictionary!
            name = (info["CFBundleDisplayName"] as? String) ?? info["CFBundleName"] as! String
            bundleID = info["CFBundleIdentifier"] as! String
            version = info["CFBundleShortVersionString"] as! String
            buildVersion = info["CFBundleVersion"] as! String
            isTestFlight = Bundle.main.appStoreReceiptURL?.path.contains("sandboxReceipt") == true
        }
        #endif
    }
    
    public let device: DeviceInfo
    public let system: SystemInfo
    public let app: AppInfo
    
    #if canImport(UIKit)
    public init() {
        device = DeviceInfo()
        system = SystemInfo()
        app = AppInfo()
    }
    #endif    
}

public struct AppArgument {
    public let type: ArgumentDataType
    public let value: ArgumentValue
    
    public init(_ parsedValue: Bool) {
        type = .bool
        value = .bool(parsedValue)
    }
    
    public init(_ parsedValue: Int) {
        type = .int
        value = .int(parsedValue)
    }
    
    public init(_ parsedValue: Double) {
        type = .double
        value = .double(parsedValue)
    }
    
    public init(_ parsedValue: String) {
        type = .string
        value = .string(parsedValue)
    }
    
    public init(_ parsedValue: Date) {
        type = .date
        value = .date(parsedValue)
    }
    
    public init(_ parsedValue: Data) {
        type = .file
        value = .file(parsedValue)
    }
    
}

public struct AppCommand {
    
    public typealias CommandName = String
    public typealias ArgumentName = String
    
    public let version: Int
    public let commands: [CommandName]
    public let arguments: [ArgumentName: AppArgument]
    
    public init(commands: [CommandName], arguments: [ArgumentName: AppArgument]) {
        version = 1
        self.commands = commands
        self.arguments = arguments
    }
}

extension AppCommand: Codable {
    
    enum CodingKeys: String, CodingKey {
        case version
        case commands
        case arguments
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(Int.self, forKey: .version)
        commands = try container.decode([CommandName].self, forKey: .commands)
        arguments = try container.decode([ArgumentName: AppArgument].self, forKey: .arguments)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(commands, forKey: .commands)
        try container.encode(arguments, forKey: .arguments)
    }
}

extension AppArgument: Codable {
    
    enum CodingKeys: String, CodingKey {
        case type
        case value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(ArgumentDataType.self, forKey: .type)
        switch type {
        case .bool:
            value = .bool(try container.decode(Bool.self, forKey: .value))
        case .int:
            value = .int(try container.decode(Int.self, forKey: .value))
        case .double:
            value = .double(try container.decode(Double.self, forKey: .value))
        case .string:
            value = .string(try container.decode(String.self, forKey: .value))
        case .date:
            value = .date(try container.decode(Date.self, forKey: .value))
        case .file:
            let data = try container.decode(Data.self, forKey: .value)
            value = .file(data)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        switch value {
        case .bool(let value):
            try container.encode(value, forKey: .value)
        case .int(let value):
            try container.encode(value, forKey: .value)
        case .double(let value):
            try container.encode(value, forKey: .value)
        case .string(let value):
            try container.encode(value, forKey: .value)
        case .date(let value):
            try container.encode(value, forKey: .value)
        case .file(let value):
            try container.encode(value, forKey: .value)
        }
    }
}
