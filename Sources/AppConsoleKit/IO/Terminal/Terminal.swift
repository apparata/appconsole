
import Foundation

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

public enum TerminalType {
    case terminal(String)
    case dumb
    case file
    
    var isTerminal: Bool {
        switch self {
        case .terminal(_): return true
        default: return false
        }
    }
}

public final class Terminal {
    
    public static var columnCount: Int {
        let columnsRaw = getenv("COLUMNS")
        let columnsString = columnsRaw.flatMap { String(validatingUTF8: $0) }
        
        if let columnsString = columnsString,
            let columnCount = Int(columnsString) {
            return columnCount
        }
            
        var windowSize = winsize()
        if ioctl(1, UInt(TIOCGWINSZ), &windowSize) == 0 {
            return Int(windowSize.ws_col)
        }
            
        return 80
    }
    
    public static func type(fileHandle: FileHandle) -> TerminalType {
        let terminalRaw = getenv("TERM")
        let terminal = terminalRaw.flatMap { String(validatingUTF8: $0) }
        if terminal?.lowercased() == "dumb" {
            return .dumb
        }
        return isatty(fileHandle.fileDescriptor) == 1 ? .terminal(terminal ?? "generic") : .file
    }
}

public extension Terminal {
    
    public static func type(output: OutputHandle) -> TerminalType {
        if let wrapper = output as? WrapsFileHandle {
            return type(fileHandle: wrapper.fileHandle)
        } else {
            return .file // Better safe than sorry.
        }
    }
}
