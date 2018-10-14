
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
