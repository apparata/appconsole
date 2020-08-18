//
//  Copyright © 2018 Apparata AB. All rights reserved.
//

import Foundation

public enum CommandSpecificationError: Error {
    case incorrectCommandSpecificationVersion
}

public struct RunCommandRequest {
    
    public typealias CommandName = String
    public typealias ArgumentName = String
    
    public static let currentVersion = 1
    
    public let version: Int
    public let commands: [CommandName]
    public let arguments: [ArgumentName: ArgumentValue]
    
    public init(commands: [CommandName], arguments: [ArgumentName: ArgumentValue]) {
        version = RunCommandRequest.currentVersion
        self.commands = commands
        self.arguments = arguments
    }
}

// MARK: - Argument

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
    case file(name: String, Data)
}

public protocol Argument {
    var argumentType: String { get }
    var name: String { get }
    var description: String { get }
}

// MARK: - Flag

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
public struct Flag: Argument, Codable {
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

// MARK: - Option

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
public struct Option: Argument, Codable {
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

// MARK: - Input

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
public struct Input: Argument, Codable {
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

// MARK: - Command

/// A command has either subcommands, or flags/options/inputs
public struct Command: Codable {
    
    public enum Context {
        case subcommands([Command])
        case arguments([Flag], [Option], [Input], isLastInputVariadic: Bool)
        
        var subcommands: [Command] {
            switch self {
            case .subcommands(let subcommands): return subcommands
            case .arguments: return []
            }
        }
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
        let helpSubcommand = Command.makeHelpSubcommand()
        let extendedSubcommands = [helpSubcommand] + subcommands
        context = .subcommands(extendedSubcommands)
        self.description = description
    }
    
    public init(name: String,
                description: String,
                isLastInputVariadic: Bool = false,
                arguments: [Argument] = []) {
        self.name = name
        let flags = arguments.filter { $0 is Flag }.map { $0 as! Flag }
        let options = arguments.filter { $0 is Option }.map { $0 as! Option }
        let inputs = arguments.filter { $0 is Input }.map { $0 as! Input }
        let helpAndFlags = [Command.makeHelpFlag()] + flags
        context = .arguments(helpAndFlags, options, inputs, isLastInputVariadic: isLastInputVariadic)
        self.description = description
    }
    
    private static func makeHelpSubcommand() -> Command {
        let arguments: [Argument] = [
            Input("subcommand", type: .string, isOptional: true, description: "Subcommand to display help text for.")
        ]
        
        let subcommandDefinition = Command(name: "help",
                                           description: "Use 'help &lt;subcommand&gt;' to display help text for subcommand.",
                                           arguments: arguments)
        return subcommandDefinition
    }
    
    private static func makeHelpFlag() -> Flag {
        return Flag("help", short: "h", description: "Show this help text.")
    }
}

// MARK: - CommandsSpecification

public struct CommandsSpecification {
    
    public static let currentVersion = 1
    
    public let version: Int
    public let commands: [Command]
    
    public init(commands: [Command]) {
        version = CommandsSpecification.currentVersion
        self.commands = commands
    }
}

// MARK: - Codable Extensions

extension RunCommandRequest: Codable {
    
    enum CodingKeys: String, CodingKey {
        case version
        case commands
        case arguments
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(Int.self, forKey: .version)
        guard version == RunCommandRequest.currentVersion else {
            throw CommandSpecificationError.incorrectCommandSpecificationVersion
        }
        commands = try container.decode([CommandName].self, forKey: .commands)
        arguments = try container.decode([ArgumentName: ArgumentValue].self, forKey: .arguments)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(commands, forKey: .commands)
        try container.encode(arguments, forKey: .arguments)
    }
}

extension ArgumentValue: Codable {
    
    enum CodingKeys: String, CodingKey {
        case type
        case value
        case name
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ArgumentDataType.self, forKey: .type)
        switch type {
        case .bool:
            self = .bool(try container.decode(Bool.self, forKey: .value))
        case .int:
            self = .int(try container.decode(Int.self, forKey: .value))
        case .double:
            self = .double(try container.decode(Double.self, forKey: .value))
        case .string:
            self = .string(try container.decode(String.self, forKey: .value))
        case .date:
            self = .date(try container.decode(Date.self, forKey: .value))
        case .file:
            let data = try container.decode(Data.self, forKey: .value)
            let name = try container.decode(String.self, forKey: .name)
            self = .file(name: name, data)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .bool(let value):
            try container.encode(ArgumentDataType.bool, forKey: .type)
            try container.encode(value, forKey: .value)
        case .int(let value):
            try container.encode(ArgumentDataType.int, forKey: .type)
            try container.encode(value, forKey: .value)
        case .double(let value):
            try container.encode(ArgumentDataType.double, forKey: .type)
            try container.encode(value, forKey: .value)
        case .string(let value):
            try container.encode(ArgumentDataType.string, forKey: .type)
            try container.encode(value, forKey: .value)
        case .date(let value):
            try container.encode(ArgumentDataType.date, forKey: .type)
            try container.encode(value, forKey: .value)
        case .file(name: let name, let value):
            try container.encode(ArgumentDataType.file, forKey: .type)
            try container.encode(value, forKey: .value)
            try container.encode(name, forKey: .name)
        }
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

extension CommandsSpecification: Codable {
    
    enum CodingKeys: String, CodingKey {
        case version
        case commands
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(Int.self, forKey: .version)
        guard version == CommandsSpecification.currentVersion else {
            throw CommandSpecificationError.incorrectCommandSpecificationVersion
        }
        commands = try container.decode([Command].self, forKey: .commands)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(commands, forKey: .commands)
    }
}
