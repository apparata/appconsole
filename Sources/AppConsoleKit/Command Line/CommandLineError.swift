
import Foundation

public enum CommandLineError: LocalizedError {
    
    case unexpectedError
    case invalidFlagOrOption(String)
    case unexpectedArgument(String)
    case missingOptionValue(Option)
    case missingInputArgument(Input)
    case invalidOptionValueFormat(Option)
    case invalidInputValueFormat(Input)
    case usageRequested(Command, Command?)
    case noSuchCommand(String)
    case noSuchSubcommand(String)
    case argumentValueNotConvertibleToType(Argument, String, ArgumentDataType)
    case failedToTokenizeCommandLine(String)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case .unexpectedError:
            return "Error: There was an unexpected error while parsing the command line."
        case .invalidFlagOrOption(let flagOrOption):
            return "Error: Invalid flag or option \"\(flagOrOption)\""
        case .unexpectedArgument(let argument):
            return "Error: Unexpected argument \"\(argument)\""
        case .missingOptionValue(let option):
            return "Error: Missing value for option \"\(option.name)\""
        case .missingInputArgument(let input):
            return "Error: Missing value for input argument \"\(input.name)\""
        case .invalidOptionValueFormat(let option):
            return "Error: Incorrect format for option \(option.name)"
        case .invalidInputValueFormat(let input):
            return "Error: Incorrect format for input argument \(input.name)"
        case .usageRequested(let command, let subcommand):
            return CommandUsage.formatUsage(for: subcommand ?? command)
        case .noSuchCommand(let name):
            return "Error: There is no command '\(name)'"
        case .noSuchSubcommand(let name):
            return "Error: There is no subcommand '\(name)'"
        case .argumentValueNotConvertibleToType(let argument, let value, let type):
            return "Error: Option '\(argument.name)' value '\(value)' is not convertible to type '\(type.rawValue)'"
        case .failedToTokenizeCommandLine(let commandLine):
            return "Error: Failed to tokenize commandline: '\(commandLine)'"
        }
    }
    
    /// A localized message describing the reason for the failure.
    public var failureReason: String? {
        return errorDescription
    }
}
