
import Foundation

public class CommandLineProcessor {
    
    public init() { }
    
    public func evaluate(_ commandLine: String, commands: [Command]) throws -> AppCommand {
        let tokenizer = CommandLineTokenizer()
        guard let arguments = tokenizer.tokenize(commandLine), arguments.count > 0 else {
            throw CommandLineError.failedToTokenizeCommandLine(commandLine)
        }
        let parsedCommand = try evaluate(arguments: arguments, commands: commands)
        return parsedCommand
    }
    
    public func evaluate(arguments: [String], commands: [Command]) throws -> AppCommand {
        
        let commandName = arguments[0]
        let arguments = Array(arguments.dropFirst())
        
        guard let commandDefinition = commands.first(where: { $0.name == commandName }) else {
            throw CommandLineError.noSuchCommand(commandName)
        }
        
        let parser = CommandLineParser(command: commandDefinition)
        let parsedCommand = try parser.parse(arguments)
        
        return parsedCommand
    }
}
