
import Foundation

class CommandLineTokenizer {
    
    let nonWordCharacter = CharacterSet(charactersIn: "\"\\").union(.whitespacesAndNewlines)
    let escapeOrQuote = CharacterSet(charactersIn: "\"\\")
    
    init() {
        
    }
    
    func tokenize(_ commandLine: String) -> [String]? {
        
        var tokens: [String] = []
        
        let trimmedCommandLine = commandLine.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: trimmedCommandLine)
        scanner.charactersToBeSkipped = nil
        
        while !scanner.isAtEnd {
            
            guard let word = scanWord(scanner) else {
                break
            }
            tokens.append(word)
            
            guard scanner.scanCharacters(from: .whitespacesAndNewlines, into: nil) else {
                break
            }
            
            if scanner.scanString("\"", into: nil) {
                guard let string = scanString(scanner) else {
                    break
                }
                tokens.append(string)
                
                guard scanner.scanCharacters(from: .whitespacesAndNewlines, into: nil) else {
                    break
                }
            }
        }
        
        guard scanner.isAtEnd else {
            return nil
        }
        
        return tokens
    }
    
    private func scanWord(_ scanner: Scanner) -> String? {
        var output: String = ""
        while !scanner.isAtEnd {
            var text: NSString?
            if scanner.scanUpToCharacters(from: nonWordCharacter, into: &text), let text = text as String? {
                output.append(text)
            }
            if scanner.scanString("\\\\", into: nil) {
                output.append("\\")
            } else if scanner.scanString("\\\"", into: nil) {
                output.append("\"")
            } else {
                break
            }
        }
        return output == "" ? nil : output
    }
    
    private func scanString(_ scanner: Scanner) -> String? {
        var output: String = ""
        while !scanner.isAtEnd {
            var text: NSString?
            if scanner.scanUpToCharacters(from: escapeOrQuote, into: &text), let text = text as String? {
                output.append(text)
            }
            if scanner.scanString("\\\\", into: nil) {
                output.append("\\")
            } else if scanner.scanString("\\\"", into: nil) {
                output.append("\"")
            } else if scanner.scanString("\"", into: nil) {
                break
            } else {
                break
            }
        }
        return output == "" ? nil : output
    }
}
