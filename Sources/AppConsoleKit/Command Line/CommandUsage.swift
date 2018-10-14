import Foundation

public final class CommandUsage {
    
    static public func formatUsage(for command: Command) -> String {
        
        let description = formatDescription(command: command)
        let commandLine = formatCommandLine(command: command)
        let subcommands = formatSubcommands(command: command)
        let flags = formatFlags(command: command)
        let options = formatOptions(command: command)
        let inputs = formatInputs(command: command)
        
        let usage = [
            description,
            commandLine,
            subcommands,
            flags,
            options,
            inputs,
        ].compactMap { $0 }
        
        return usage.joined(separator: "\n").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    static private func formatDescription(command: Command) -> String? {
        return "OVERVIEW: \(command.description)\n"
    }
    
    static private func formatCommandLine(command: Command) -> String {
        
        var text: String = "USAGE: " + command.name
        
        switch command.context {
        case .subcommands(_):
            text += " [subcommand [arguments]]"
        case .arguments(let flags, let options, let inputs, _):
            if flags.count > 0 {
                text += " [flags]"
            }
            if options.count > 0 {
                text += " [options]"
            }
            if inputs.count > 0 {
                text += " <inputs>"
            }
        }
        text += "\n"
        return text
    }
    
    static private func formatSubcommands(command: Command) -> String? {
        guard case let .subcommands(subcommands) = command.context, subcommands.count > 0 else {
            return nil
        }
        var text = "SUBCOMMANDS:\n"
        
        for subcommand in subcommands {
            var row = "  \(subcommand.name)"
            row += calculatePadding(string: row)
            row += "\(subcommand.description)\n"
            text += row
        }
        
        return text
    }
    
    static private func formatFlags(command: Command) -> String? {
        
        guard case let .arguments(flags, _, _, _) = command.context, flags.count > 0 else {
            return nil
        }
        
        var text = "FLAGS:\n"
        
        for flag in flags {
            var row = "  "
            row += "-\(flag.short), "
            row += "--\(flag.name)"
            row += calculatePadding(string: row)
            row += "\(flag.description)\n"
            text += row
        }
        
        return text
    }
    
    static private func formatOptions(command: Command) -> String? {
        guard case let .arguments(_, options, _, _) = command.context, options.count > 0 else {
            return nil
        }
        
        var text = "OPTIONS:\n"
        
        for option in options {
            var row = "  "
            row += "-\(option.short), "
            row += "--\(option.name) <\(option.name)>"
            row += calculatePadding(string: row)
            row += "\(option.description)"
            
            row += "\n"
            text += row
        }
        
        return text
    }
    
    static private func formatInputs(command: Command) -> String? {
        guard case let .arguments(_, _, inputs, _) = command.context, inputs.count > 0 else {
            return nil
        }
        
        var text = "INPUTS:\n"
        
        for input in inputs {
            var row = "  "
            row += "\(input.name)"
            row += calculatePadding(string: row)
            if input.isOptional {
                row += "\(input.description) (OPTIONAL)\n"
            } else {
                row += "\(input.description)\n"
            }
            text += row
        }
        
        return text
    }
    
    static private func calculatePadding(string: String, columns: Int = 26) -> String {
        let length = string.count
        if length + 1 > columns {
            return "\n" + String(repeating: " ", count: columns)
        } else {
            return String(repeating: " ", count: columns - string.count)
        }
    }
}
