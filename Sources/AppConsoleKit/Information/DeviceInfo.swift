//
//  Copyright © 2018 Apparata AB. All rights reserved.
//

import Foundation

public enum DeviceType {

    case iPodTouch5thGen
    case iPodTouch6thGen
    
    case iPhone4
    case iPhone4s
    case iPhone5
    case iPhone5c
    case iPhone5s
    case iPhone6
    case iPhone6Plus
    case iPhone6s
    case iPhone6sPlus
    case iPhone7
    case iPhone7Plus
    case iPhoneSE
    case iPhone8
    case iPhone8Plus
    case iPhoneX
    case iPhoneXs
    case iPhoneXsMax
    case iPhoneXr
    
    case iPad2
    case iPad3
    case iPad4
    case iPadAir
    case iPadAir2
    case iPad5
    case iPad6
    case iPadMini
    case iPadMini2
    case iPadMini3
    case iPadMini4
    case iPadPro9Inch
    case iPadPro12Inch
    case iPadPro12Inch2
    case iPadPro10Inch
    case iPadPro11Inch
    case iPadPro12Inch3
    
    case homePod
    
    case appleTV4
    case appleTV4K
    
    case simulator
    
    /// Device is not yet known
    case unknown(String)
    
    public init(identifier: String) {
        
        switch identifier {
        case "iPod5,1": self = .iPodTouch5thGen
        case "iPod7,1": self = .iPodTouch6thGen
            
        case "iPhone3,1", "iPhone3,2", "iPhone3,3": self = .iPhone4
        case "iPhone4,1": self = .iPhone4s
        case "iPhone5,1", "iPhone5,2": self = .iPhone5
        case "iPhone5,3", "iPhone5,4": self = .iPhone5c
        case "iPhone6,1", "iPhone6,2": self = .iPhone5s
        case "iPhone7,2": self = .iPhone6
        case "iPhone7,1": self = .iPhone6Plus
        case "iPhone8,1": self = .iPhone6s
        case "iPhone8,2": self = .iPhone6sPlus
        case "iPhone9,1", "iPhone9,3": self = .iPhone7
        case "iPhone9,2", "iPhone9,4": self = .iPhone7Plus
        case "iPhone8,4": self = .iPhoneSE
        case "iPhone10,1", "iPhone10,4": self = .iPhone8
        case "iPhone10,2", "iPhone10,5": self = .iPhone8Plus
        case "iPhone10,3", "iPhone10,6": self = .iPhoneX
        case "iPhone11,2": self = .iPhoneXs
        case "iPhone11,4", "iPhone11,6": self = .iPhoneXsMax
        case "iPhone11,8": self = .iPhoneXr
            
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4": self = .iPad2
        case "iPad3,1", "iPad3,2", "iPad3,3": self = .iPad3
        case "iPad3,4", "iPad3,5", "iPad3,6": self = .iPad4
        case "iPad4,1", "iPad4,2", "iPad4,3": self = .iPadAir
        case "iPad5,3", "iPad5,4": self = .iPadAir2
        case "iPad6,11", "iPad6,12": self = .iPad5
        case "iPad7,5", "iPad7,6": self = .iPad6
        case "iPad2,5", "iPad2,6", "iPad2,7": self = .iPadMini
        case "iPad4,4", "iPad4,5", "iPad4,6": self = .iPadMini2
        case "iPad4,7", "iPad4,8", "iPad4,9": self = .iPadMini3
        case "iPad5,1", "iPad5,2": self = .iPadMini4
        case "iPad6,3", "iPad6,4": self = .iPadPro9Inch
        case "iPad6,7", "iPad6,8": self = .iPadPro12Inch
        case "iPad7,1", "iPad7,2": self = .iPadPro12Inch2
        case "iPad7,3", "iPad7,4": self = .iPadPro10Inch
        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4": self = .iPadPro11Inch
        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8": self = .iPadPro12Inch3

        case "AudioAccessory1,1": self = .homePod

        case "AppleTV5,3": self = .appleTV4
        case "AppleTV6,2": self = .appleTV4K

        case "i386", "x86_64": self = .simulator
        default: self = .unknown(identifier)
        }
    }
}

extension DeviceType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .iPodTouch5thGen: return "iPod Touch 5th Gen"
        case .iPodTouch6thGen: return "iPod Touch 6th Gen"
            
        case .iPhone4: return "iPhone 4"
        case .iPhone4s: return "iPhone 4s"
        case .iPhone5: return "iPhone 5"
        case .iPhone5c: return "iPhone 5c"
        case .iPhone5s: return "iPhone 5s"
        case .iPhone6: return "iPhone 6"
        case .iPhone6Plus: return "iPhone 6 Plus"
        case .iPhone6s: return "iPhone 6s"
        case .iPhone6sPlus: return "iPhone 6s Plus"
        case .iPhone7: return "iPhone 7"
        case .iPhone7Plus: return "iPhone 7 Plus"
        case .iPhoneSE: return "iPhone SE"
        case .iPhone8: return "iPhone 8"
        case .iPhone8Plus: return "iPhone 8 Plus"
        case .iPhoneX: return "iPhone X"
        case .iPhoneXs: return "iPhone Xs"
        case .iPhoneXsMax: return "iPhone Xs Max"
        case .iPhoneXr: return "iPhone Xr"
            
        case .iPad2: return "iPad 2"
        case .iPad3: return "iPad 3"
        case .iPad4: return "iPad 4"
        case .iPad5: return "iPad 5"
        case .iPad6: return "iPad 6"
        case .iPadAir: return "iPad Air"
        case .iPadAir2: return "iPad Air 2"
        case .iPadMini: return "iPad Mini"
        case .iPadMini2: return "iPad Mini 2"
        case .iPadMini3: return "iPad Mini 3"
        case .iPadMini4: return "iPad Mini 4"
        case .iPadPro9Inch: return "iPad Pro (9.7\")"
        case .iPadPro12Inch: return "iPad Pro (12.9\")"
        case .iPadPro12Inch2: return "iPad Pro (12.9\", 2nd Gen)"
        case .iPadPro10Inch: return "iPad Pro (10.5\")"
        case .iPadPro11Inch: return "iPad Pro (11\")"
        case .iPadPro12Inch3: return "iPad Pro (12.9\", 3rd Gen)"
            
        case .homePod: return "HomePod"

        case .appleTV4: return "Apple TV 4"
        case .appleTV4K: return "Apple TV 4K"

        case .simulator: return "Simulator"
        case .unknown(let identifier): return identifier
        }
    }
}

extension DeviceType: Equatable {}

public func ==(lhs: DeviceType, rhs: DeviceType) -> Bool {
    return lhs.description == rhs.description
}
