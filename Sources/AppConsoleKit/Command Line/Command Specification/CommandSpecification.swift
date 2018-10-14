//
//  Copyright © 2018 Apparata AB. All rights reserved.
//

import Foundation

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


// ----------------------------------------------------------------------------
// MARK: - Argument
// ----------------------------------------------------------------------------

public enum ArgumentDataType: String, Codable {
    case bool
    case int
    case double
    case string
    case date
    case file
}

public enum ArgumentValue {
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case date(Date)
    case file(Data)
}

public protocol Argument {
    var argumentType: String { get }
    var name: String { get }
    var description: String { get }
}

// ----------------------------------------------------------------------------
// MARK: - Flag
// ----------------------------------------------------------------------------

/// A flag is an argument, which when present, represents `true`.
/// A flag that is not present, represents `false`.
///
/// Example: `-v` or `--verbose`
///
/// ```
/// {
///     "argumentType": "flag",
///     "name": "verbose",
///     "short": "v",
///     "description": "Verbose output form command."
/// }
/// ```
///
public struct Flag: Argument {
    public let argumentType: String
    public let name: String
    public let short: String
    public let description: String
    
    public init(_ name: String, short: String, description: String) {
        argumentType = "flag"
        self.name = name
        self.short = short
        self.description = description
    }
}

extension Flag: Codable {
    
    enum CodingKeys: String, CodingKey {
        case argumentType
        case name
        case short
        case description
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        argumentType = try container.decode(String.self, forKey: .argumentType)
        name = try container.decode(String.self, forKey: .name)
        short = try container.decode(String.self, forKey: .short)
        description = try container.decode(String.self, forKey: .description)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(argumentType, forKey: .argumentType)
        try container.encode(name, forKey: .name)
        try container.encode(short, forKey: .short)
        try container.encode(description, forKey: .description)
    }
}

// ----------------------------------------------------------------------------
// MARK: - Option
// ----------------------------------------------------------------------------

/// An option argument represents a named option and is used to pass a value
/// to the command.
///
/// Example: `-p 8` or `--passes 8`
///
/// ```
/// {
///     "argumentType": "option",
///     "name": "passes",
///     "short": "p",
///     "type": "int",
///     "isMultipleAllowed": false,
///     "validationRegex": "^\\d+$",
///     "description": "The number of things."
/// }
/// ```
///
public struct Option: Argument {
    public let argumentType: String
    public let name: String
    public let short: String
    public let type: ArgumentDataType
    public let isMultipleAllowed: Bool
    public let validationRegex: String?
    public let description: String
    
    public init(_ name: String,
                short: String,
                type: ArgumentDataType,
                isMultipleAllowed: Bool,
                validationRegex: String? = nil,
                description: String) {
        argumentType = "option"
        self.name = name
        self.short = short
        self.type = type
        self.isMultipleAllowed = isMultipleAllowed
        self.validationRegex = validationRegex
        self.description = description
    }
}

extension Option: Codable {
    
    enum CodingKeys: String, CodingKey {
        case argumentType
        case name
        case short
        case type
        case isMultipleAllowed
        case validationRegex
        case description
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        argumentType = try container.decode(String.self, forKey: .argumentType)
        name = try container.decode(String.self, forKey: .name)
        short = try container.decode(String.self, forKey: .short)
        type = try container.decode(ArgumentDataType.self, forKey: .type)
        isMultipleAllowed = try container.decode(Bool.self, forKey: .isMultipleAllowed)
        validationRegex = try container.decodeIfPresent(String.self, forKey: .validationRegex)
        description = try container.decode(String.self, forKey: .description)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(argumentType, forKey: .argumentType)
        try container.encode(name, forKey: .name)
        try container.encode(short, forKey: .short)
        try container.encode(type, forKey: .type)
        try container.encode(isMultipleAllowed, forKey: .isMultipleAllowed)
        try container.encodeIfPresent(validationRegex, forKey: .validationRegex)
        try container.encode(description, forKey: .description)
    }
}


// ----------------------------------------------------------------------------
// MARK: - Input
// ----------------------------------------------------------------------------

/// An input argument is an argument that represents a file or similar.
/// If it's the last argument, it could optionally be variadic.
///
/// Example: `aFile.txt` or `file1.txt file2.txt file3.txt`
///
/// ```
/// {
///     "argumentType": "input",
///     "name": "inputFile",
///     "type": "file",
///     "isOptional": false,
///     "validationRegex": "^.*\\.txt$"
///     "description": "The input text file."
/// }
/// ```
///
public struct Input: Argument {
    public let argumentType: String
    public let name: String
    public let type: ArgumentDataType
    public let isOptional: Bool
    public let validationRegex: String?
    public let description: String
    
    public init(_ name: String,
                type: ArgumentDataType,
                isOptional: Bool,
                validationRegex: String? = nil,
                description: String) {
        argumentType = "input"
        self.name = name
        self.type = type
        self.isOptional = isOptional
        self.validationRegex = validationRegex
        self.description = description
    }
}

extension Input: Codable {
    
    enum CodingKeys: String, CodingKey {
        case argumentType
        case name
        case type
        case isOptional
        case validationRegex
        case description
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        argumentType = try container.decode(String.self, forKey: .argumentType)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(ArgumentDataType.self, forKey: .type)
        isOptional = try container.decode(Bool.self, forKey: .isOptional)
        validationRegex = try container.decodeIfPresent(String.self, forKey: .validationRegex)
        description = try container.decode(String.self, forKey: .description)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(argumentType, forKey: .argumentType)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(isOptional, forKey: .isOptional)
        try container.encodeIfPresent(validationRegex, forKey: .validationRegex)
        try container.encode(description, forKey: .description)
    }
}

// ----------------------------------------------------------------------------
// MARK: - Command
// ----------------------------------------------------------------------------

/// A command has either subcommands, or flags/options/inputs
public struct Command {
    
    public enum Context {
        case subcommands([Command])
        case arguments([Flag], [Option], [Input], isLastInputVariadic: Bool)
    }
    
    public let name: String
    public let description: String
    
    public let context: Context
    
    var hasSubcommands: Bool {
        if case .subcommands = context {
            return true
        }
        return false
    }
    
    var argumentCount: Int {
        if case let .arguments(flags, options, inputs, _) = context {
            return flags.count + options.count + inputs.count
        }
        return 0
    }
    
    public init(name: String,
                description: String,
                subcommands: [Command]) {
        self.name = name
        let helpSubcommand = Command.createHelpSubcommand()
        let extendedSubcommands = [helpSubcommand] + subcommands
        context = .subcommands(extendedSubcommands)
        self.description = description
    }
    
    public init(name: String,
                description: String,
                isLastInputVariadic: Bool = false,
                arguments: [Argument]) {
        self.name = name
        let flags = arguments.filter { $0 is Flag }.map { $0 as! Flag }
        let options = arguments.filter { $0 is Option }.map { $0 as! Option }
        let inputs = arguments.filter { $0 is Input }.map { $0 as! Input }
        let helpAndFlags = [Command.createHelpFlag()] + flags
        context = .arguments(helpAndFlags, options, inputs, isLastInputVariadic: isLastInputVariadic)
        self.description = description
    }
    
    private static func createHelpSubcommand() -> Command {
        let arguments: [Argument] = [
            Input("subcommand", type: .string, isOptional: true, description: "Subcommand to display help text for.")
        ]
        
        let subcommandDefinition = Command(name: "help",
                                           description: "Use 'help &lt;subcommand&gt;' to display help text for subcommand.",
                                           arguments: arguments)
        return subcommandDefinition
    }
    
    private static func createHelpFlag() -> Flag {
        return Flag("help", short: "h", description: "Show this help text.")
    }
}

extension Command: Codable {
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case context
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        context = try container.decode(Context.self, forKey: .context)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(context, forKey: .context)
    }
}

extension Command.Context: Codable {
    
    enum CodingKeys: String, CodingKey {
        case subcommands
        case flags
        case options
        case inputs
        case isLastInputVariadic
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let subcommands = try container.decodeIfPresent([Command].self, forKey: .subcommands) {
            self = .subcommands(subcommands)
        } else {
            let isLastInputVariadic = try container.decode(Bool.self, forKey: .isLastInputVariadic)
            let flags = try container.decodeIfPresent([Flag].self, forKey: .flags) ?? []
            let options = try container.decodeIfPresent([Option].self, forKey: .options) ?? []
            let inputs = try container.decodeIfPresent([Input].self, forKey: .inputs) ?? []
            self = .arguments(flags, options, inputs, isLastInputVariadic: isLastInputVariadic)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .subcommands(let subcommands):
            try container.encode(subcommands, forKey: .subcommands)
        case .arguments(let flags, let options, let inputs, let isLastInputVariadic):
            try container.encode(flags, forKey: .flags)
            try container.encode(options, forKey: .options)
            try container.encode(inputs, forKey: .inputs)
            try container.encode(isLastInputVariadic, forKey: .isLastInputVariadic)
        }
    }
}

// ----------------------------------------------------------------------------
// MARK: - CommandsSpecification
// ----------------------------------------------------------------------------

public struct CommandsSpecification {
    public let version: Int
    public let commands: [Command]
    
    public init(commands: [Command]) {
        version = 1
        self.commands = commands
    }
}

extension CommandsSpecification: Codable {
    
    enum CodingKeys: String, CodingKey {
        case version
        case commands
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(Int.self, forKey: .version)
        commands = try container.decode([Command].self, forKey: .commands)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(commands, forKey: .commands)
    }
}

