
import Foundation

public extension String {
    
    /// Returns a string with ANSI terminal codes based on markup in string.
    ///
    /// Tags can be nested. Attributes take precedence inside and out.
    ///
    /// Tags are writen with angular brackets `<tag>`. Closing tag names begin
    /// with a forward slash `</tag>`. Use `&lt;` and `&gt;` to escape angular
    /// brackets, as in HTML. `&amp;` escapes &.
    ///
    /// Example:
    /// ```
    /// let attributes: [String: [NSAttributedStringKey: AnyObject]] = [
    ///     "loud": [.font: UIFont.systemFont(ofSize: 40)],
    ///     "green": [.color: UIColor.green]
    /// ]
    ///
    /// let string = "Testing <green>this text is green</green>.".forTerminal()
    /// ```
    ///
    /// - Parameter type: If terminal type is not .tty, string will be plain.
    /// - Parameter reset: Reset the style at the start and end of string.
    /// - Returns: Returns styled string
    ///
    func forTerminal(type: TerminalType, reset: Bool = true) -> String {
        return TerminalString(self).forTerminal(type: type, reset: reset)
    }
    
    /// Returns a string with ANSI terminal codes based on markup in string,
    /// if the terminal type of the console is .tty, otherwise plain string.
    ///
    /// Tags can be nested. Attributes take precedence inside and out.
    ///
    /// Tags are writen with angular brackets `<tag>`. Closing tag names begin
    /// with a forward slash `</tag>`. Use `&lt;` and `&gt;` to escape angular
    /// brackets, as in HTML. `&amp;` escapes &.
    ///
    /// Example:
    /// ```
    /// let string = "Testing <green>this text is green</green>.".forConsole()
    /// ```
    ///
    /// - Parameter reset: Reset the style at the start and end of string.
    /// - Returns: Returns styled string
    ///
    func forConsole(reset: Bool = true) -> String {
        return TerminalString(self).forTerminal(type: Console.terminalType, reset: reset)
    }
    
    /// Escapes tags so the string can be safely inserted in a terminal string.
    func escapedTags() -> String {
        return self
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "&", with: "&amp;")
    }
}

/// The `TerminalString` struct is a wrapper around strings that contain simple
/// markup for the purpose of easily creating ANSI color coded strings.
///
/// Tags can be nested. Attributes take precedence inside and out.
///
/// Tags are writen with angular brackets `<tag>`. Closing tag names begin
/// with a forward slash `</tag>`. Use `&lt;` and `&gt;` to escape angular
/// brackets, as in HTML. `&amp;` escapes &.
///
///
/// let string: TagString = "Testing <onRed>this <green>text</green></onRed> thing."
/// string.forTerminal()
/// ```
///
public struct TerminalString {
    
    public typealias Attributes = [String: [NSAttributedString.Key: AnyObject]]
    
    private enum TagStringToken {
        case text(String)
        case entity(String)
        case startTag(String)
        case endTag(String)
    }
    
    private let entities = ["lt": "<", "gt": ">", "amp": "&"]
    
    /// The raw string passed into the initializer.
    public let string: String
    
    public init(_ string: String) {
        self.string = string
    }
    
    /// Example:
    /// ```
    /// let string: TerminalString = "Testing <onRed>this <green>text</green></onRed> thing."
    /// string.terminal
    /// ```
    ///
    /// - Parameter reset: Add reset code to start and end of string.
    /// - Returns: Returns styled string or unstyled string if tags don't match.
    ///
    public func forTerminal(type: TerminalType, reset: Bool = true) -> String {
        if let tokenizedText = tokenize(string: self.string) {
            if type.isTerminal, !Execution.isDebuggerAttached {
                let styledString = buildString(tokenizedText: tokenizedText)
                if reset {
                    return "\u{001B}[0m\(styledString)\u{001B}[0m"
                } else {
                    return styledString
                }
            } else {
                return buildPlainString(tokenizedText: tokenizedText)
            }
        } else {
            return self.string
        }
    }
    
    // MARK: - Tokenizer
    
    private func tokenize(string: String) -> [TagStringToken]? {
        
        var tokens = [TagStringToken]()
        
        let scanner = Scanner(string: string)
        scanner.charactersToBeSkipped = nil
        
        while !scanner.isAtEnd {
            if let textToken = scanText(scanner: scanner) {
                tokens.append(textToken)
            }
            
            if scanner.isAtEnd {
                break
            }
            
            if let tagToken = scanTag(scanner: scanner) {
                tokens.append(tagToken)
            } else if let entityToken = scanEntity(scanner: scanner) {
                tokens.append(entityToken)
            } else {
                return nil
            }
        }
        
        return tokens
    }
    
    private func scanTag(scanner: Scanner) -> TagStringToken? {
        guard scanner.scanString("<", into: nil) else {
            return nil
        }
        
        let isEndTag = scanner.scanString("/", into: nil)
        
        var tag: NSString?
        guard scanner.scanUpTo(">", into: &tag) else {
            return nil
        }
        
        let token: TagStringToken
        if let tag = tag as String? {
            token = isEndTag ? TagStringToken.endTag(tag) : TagStringToken.startTag(tag)
        } else {
            return nil
        }
        
        scanner.scanString(">", into: nil)
        
        return token
    }
    
    private func scanEntity(scanner: Scanner) -> TagStringToken? {
        guard scanner.scanString("&", into: nil) else {
            return nil
        }
        
        var entity: NSString?
        guard scanner.scanUpTo(";", into: &entity) else {
            return nil
        }
        
        let token: TagStringToken
        if let entity = entity as String? {
            token = TagStringToken.entity(entity)
        } else {
            return nil
        }
        
        scanner.scanString(";", into: nil)
        
        return token
        
    }
    
    private func scanText(scanner: Scanner) -> TagStringToken? {
        var text: NSString?
        let tagOrEntityCharacters = CharacterSet(charactersIn: "<&")
        if scanner.scanUpToCharacters(from: tagOrEntityCharacters, into: &text), let text = text as String? {
            return .text(text)
        }
        return nil
    }
    
    // MARK: - String builder
    
    private func buildString(tokenizedText: [TagStringToken]) -> String {
        
        var foregroundColorStack = [String]()
        var backgroundColorStack = [String]()
        
        var outputString: String = ""
        
        for token in tokenizedText {
            switch token {
                
            case .text(let string):
                outputString.append(string)
                
            case .startTag(let tag):
                if isForegroundColorTag(tag) {
                    foregroundColorStack.append(tag)
                } else if isBackgroundColorTag(tag) {
                    backgroundColorStack.append(tag)
                }
                outputString.append(startTagToTerminalCode(tag))
                
            case .endTag(let tag):
                if isForegroundColorTag(tag) {
                    foregroundColorStack.removeLast()
                    if let previousTag = foregroundColorStack.last {
                        outputString.append(startTagToTerminalCode(previousTag))
                    } else {
                        outputString.append(startTagToTerminalCode("reset"))
                    }
                } else if isBackgroundColorTag(tag) {
                    backgroundColorStack.removeLast()
                    if let previousTag = backgroundColorStack.last {
                        outputString.append(startTagToTerminalCode(previousTag))
                    } else {
                        outputString.append(startTagToTerminalCode("reset"))
                    }
                } else {
                    outputString.append(endTagToTerminalCode(tag))
                }
                
            case .entity(let entity):
                if let string = entities[entity] {
                    outputString.append(string)
                }
            }
        }
        
        return outputString
    }

    private func buildPlainString(tokenizedText: [TagStringToken]) -> String {
        
        var outputString: String = ""
        
        for token in tokenizedText {
            switch token {
                
            case .text(let string):
                outputString.append(string)
                
            case .entity(let entity):
                if let string = entities[entity] {
                    outputString.append(string)
                }

            default:
                break
            }
        }
        
        return outputString
    }

    
    private func startTagToTerminalCode(_ tag: String) -> String {
        guard let startCode = tagToCode[tag] else {
            return ""
        }
        return startCode
    }
    
    private func endTagToTerminalCode(_ tag: String) -> String {
        guard let endCode = tagToCode["/\(tag)"] else {
            return ""
        }
        return endCode
    }
    
    private func isForegroundColorTag(_ tag: String) -> Bool {
        return ["black", "red", "green", "yellow",
                "blue", "magenta", "cyan", "white",
                "brightBlack", "brightRed", "brightGreen", "brightYellow",
                "brightBlue", "brightMagenta", "brightCyan", "brightWhite"
            ].contains(tag)
    }

    private func isBackgroundColorTag(_ tag: String) -> Bool {
        return ["onBlack", "onRed", "onGreen", "onYellow",
                "onBlue", "onMagenta", "onCyan", "onWhite",
                "onBrightBlack", "onBrightRed", "onBrightGreen", "onBrightYellow",
                "onBrightBlue", "onBrightMagenta", "onBrightCyan", "onBrightWhite"
            ].contains(tag)
    }
    
    private enum ForegroundColor: Int {
        
        case black = 30
        case red = 31
        case green = 32
        case yellow = 33
        case blue = 34
        case magenta = 35
        case cyan = 36
        case white = 37
        
        case brightBlack = 90
        case brightRed = 91
        case brightGreen = 92
        case brightYellow = 93
        case brightBlue = 94
        case brightMagenta = 95
        case brightCyan = 96
        case brightWhite = 97
        
        var terminalCode: String {
            return "\u{001B}[\(self.rawValue)m"
        }
    }
    
    private enum BackgroundColor: Int {

        case black = 40
        case red = 41
        case green = 42
        case yellow = 43
        case blue = 44
        case magenta = 45
        case cyan = 46
        case white = 47

        case brightBlack = 100
        case brightRed = 101
        case brightGreen = 102
        case brightYellow = 103
        case brightBlue = 104
        case brightMagenta = 105
        case brightCyan = 106
        case brightWhite = 107
        
        var terminalCode: String {
            return "\u{001B}[\(self.rawValue)m"
        }
    }
    
    private enum TextStyle: Int {
        case reset = 0

        case bold = 1
        case boldOff = 22

        case italic = 3
        case italicOff = 23

        case underline = 4
        case underlineOff = 24

        case inverse = 7
        case inverseOff = 27

        case strikethrough = 9
        case strikethroughOff = 29
        
        var terminalCode: String {
            return "\u{001B}[\(self.rawValue)m"
        }
    }
    
    private let tagToCode: [String: String] = [
        
        "clear": "\u{001B}[2J",
        "clearLine": "\u{001B}[2K",
        
        "black": ForegroundColor.black.terminalCode,
        "red": ForegroundColor.red.terminalCode,
        "green": ForegroundColor.green.terminalCode,
        "yellow": ForegroundColor.yellow.terminalCode,
        "blue": ForegroundColor.blue.terminalCode,
        "magenta": ForegroundColor.magenta.terminalCode,
        "cyan": ForegroundColor.cyan.terminalCode,
        "white": ForegroundColor.white.terminalCode,
        
        "brightBlack": BackgroundColor.brightBlack.terminalCode,
        "brightRed": BackgroundColor.brightRed.terminalCode,
        "brightGreen": BackgroundColor.brightGreen.terminalCode,
        "brightYellow": BackgroundColor.brightYellow.terminalCode,
        "brightBlue": BackgroundColor.brightBlue.terminalCode,
        "brightMagenta": BackgroundColor.brightMagenta.terminalCode,
        "brightCyan": BackgroundColor.brightCyan.terminalCode,
        "brightWhite": BackgroundColor.brightWhite.terminalCode,
        
        "onBlack": BackgroundColor.black.terminalCode,
        "onRed": BackgroundColor.red.terminalCode,
        "onGreen": BackgroundColor.green.terminalCode,
        "onYellow": BackgroundColor.yellow.terminalCode,
        "onBlue": BackgroundColor.blue.terminalCode,
        "onMagenta": BackgroundColor.magenta.terminalCode,
        "onCyan": BackgroundColor.cyan.terminalCode,
        "onWhite": BackgroundColor.white.terminalCode,
        
        "onBrightBlack": BackgroundColor.brightBlack.terminalCode,
        "onBrightRed": BackgroundColor.brightRed.terminalCode,
        "onBrightGreen": BackgroundColor.brightGreen.terminalCode,
        "onBrightYellow": BackgroundColor.brightYellow.terminalCode,
        "onBrightBlue": BackgroundColor.brightBlue.terminalCode,
        "onBrightMagenta": BackgroundColor.brightMagenta.terminalCode,
        "onBrightCyan": BackgroundColor.brightCyan.terminalCode,
        "onBrightWhite": BackgroundColor.brightWhite.terminalCode,
        
        "reset": TextStyle.reset.terminalCode,
        "bold": TextStyle.bold.terminalCode,
        "/bold": TextStyle.boldOff.terminalCode,
        "italic": TextStyle.italic.terminalCode,
        "/italic": TextStyle.italicOff.terminalCode,
        "underline": TextStyle.underline.terminalCode,
        "/underline": TextStyle.underlineOff.terminalCode,
        "inverse": TextStyle.inverse.terminalCode,
        "/inverse": TextStyle.inverseOff.terminalCode,
        "strikethrough": TextStyle.strikethrough.terminalCode,
        "/strikethrough": TextStyle.strikethroughOff.terminalCode
    ]
}

// This is what allows the TagString to be created from a literal string.
extension TerminalString: ExpressibleByStringLiteral {
    public typealias UnicodeScalarLiteralType = StringLiteralType
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        string = "\(value)"
    }
    
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        string = value
    }
    
    public init(stringLiteral value: StringLiteralType) {
        string = value
    }
}

