
import Foundation

public class Console {
    
    public static let standard = StandardIO()
    
    public static let lineReader = LineReader(input: standard.in)
    
    public static let terminalType: TerminalType = {
        return Terminal.type(output: standard.out)
    }()
    
    public static let errorTerminalType: TerminalType = {
        return Terminal.type(output: standard.error)
    }()
    
    // MARK: - Read
    
    public static func readLine() -> String? {
        return lineReader.readLine()
    }
    
    // MARK: - Write
    
    public static func write(_ string: @autoclosure () -> String) {
        standard.out.write(string())
    }

    public static func writeError(_ string: @autoclosure () -> String) {
        standard.error.write(string())
    }
    
    public static func writeLine(_ string: @autoclosure () -> String) {
        standard.out.writeLine(string())
    }
    
    public static func writeLineError(_ string: @autoclosure () -> String) {
        standard.error.writeLine(string())
    }
    
    public static func print(_ string: @autoclosure () -> String) {
        standard.out.writeLine(string().forConsole())
    }

    public static func printError(_ string: @autoclosure () -> String) {
        standard.error.writeLine(string().forTerminal(type: errorTerminalType))
    }
    
    // MARK: - Convenience
    
    public static func ask(question: String, default defaultValue: String?) -> String? {
        if let defaultValue = defaultValue {
            write("\(question) [\(defaultValue)] ")
        } else {
            write("\(question) ")
        }
        
        if let line = readLine() {
            switch line.lowercased() {
            case "":
                return defaultValue
            default:
                return line
            }
        } else {
            return nil
        }
    }
    
    public static func confirmYesOrNo(question: String, default defaultValue: Bool) -> Bool? {
        write("\(question) [\(defaultValue ? "Y/n" : "y/N")] ")
        if let line = readLine() {
            switch line.lowercased() {
            case "y", "yes", "yep":
                return true
            case "n", "no", "nope":
                return false
            case "":
                return defaultValue
            default:
                return nil
            }
        } else {
            return nil
        }
    }
    
    // MARK: - Clear
    
    public static func clear() {
        standard.out.write("\u{001B}[2J\r")
        flush()
    }
    
    public static func clearError() {
        standard.error.write("\u{001B}[2J\r")
        flush()
    }

    public static func clearLine() {
        standard.out.write("\u{001B}[2K\r")
        flush()
    }
    
    public static func clearLineError() {
        standard.error.write("\u{001B}[2K\r")
        flush()
    }
    
    // MARK: - Flush
    
    public static func flush() {
        standard.out.flush()
    }
    
    public static func flushError() {
        standard.error.flush()
    }
}
