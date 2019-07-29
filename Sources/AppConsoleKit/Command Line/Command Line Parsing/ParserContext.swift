
import Foundation

class ParserContext {
    var commandDefinition: Command
    var commands: [Command] = []
    var arguments: [(Argument, ArgumentValue)] = []
    
    private var remainingFlags: [Flag] = []
    private var remainingOptions: [Option] = []
    private var remainingInputs: [Input] = []
    
    init(command: Command) {
        commandDefinition = command
        commands.append(command)
        switch commandDefinition.context {
        case .arguments(let flags, let options, let inputs, _):
            remainingFlags = flags
            remainingOptions = options
            remainingInputs = inputs
        default:
            break
        }
    }
    
    func addSubcommand(_ subcommand: Command) throws {
        
        commands.append(subcommand)
        
        switch subcommand.context {
        case .arguments(let flags, let options, let inputs, _):
            remainingFlags = flags
            remainingOptions = options
            remainingInputs = inputs
        default:
            break
        }
    }
        
    func addFlag(_ flag: Flag) throws {
        if let index = remainingFlags.firstIndex(where: {
            flag.name == $0.name
        }) {
            remainingFlags.remove(at: index)
        } else {
            throw CommandLineError.unexpectedArgument(flag.name)
        }
        
        arguments.append((flag, .bool(true)))
    }
    
    func addOption(_ option: Option, stringValue: String) throws {
        if let index = remainingOptions.firstIndex(where: {
            option.name == $0.name
        }) {
            remainingOptions.remove(at: index)
        } else {
            if !option.isMultipleAllowed {
                throw CommandLineError.unexpectedArgument(option.name)
            }
        }
        
        let parsedArgument = try convertArgument(option, stringValue: stringValue, toValueOfType: option.type)

        arguments.append((option, parsedArgument))
    }
    
    func addInput(_ input: Input, stringValue: String) throws {
        if let index = remainingInputs.firstIndex(where: {
            input.name == $0.name
        }) {
            remainingInputs.remove(at: index)
        } else {
            //if !command.isLastInputVariadic {
                throw CommandLineError.unexpectedArgument(input.name)
            //}
        }
        
        let parsedArgument = try convertArgument(input, stringValue: stringValue, toValueOfType: input.type)
        
        arguments.append((input, parsedArgument))
    }
    
    private func convertArgument(_ argument: Argument, stringValue: String, toValueOfType type: ArgumentDataType) throws -> ArgumentValue {
        switch type {
        case .bool:
            guard let value = Bool(stringValue) else {
                throw CommandLineError.argumentValueNotConvertibleToType(argument, stringValue, type)
            }
            return .bool(value)
        case .int:
            guard let value = Int(stringValue) else {
                throw CommandLineError.argumentValueNotConvertibleToType(argument, stringValue, type)
            }
            return .int(value)
        case .double:
            guard let value = Double(stringValue) else {
                throw CommandLineError.argumentValueNotConvertibleToType(argument, stringValue, type)
            }
            return .double(value)
        case .string: return .string(stringValue)
        case .date:
            guard let date = ISO8601DateFormatter().date(from: stringValue) else {
                throw CommandLineError.argumentValueNotConvertibleToType(argument, stringValue, type)
            }
            return .date(date)
        case .file:
            let url = URL(fileURLWithPath: stringValue)
            guard let data = try? Data(contentsOf: url) else {
                throw CommandLineError.argumentValueNotConvertibleToType(argument, stringValue, type)
            }
            return .file(name: url.lastPathComponent, data)
        }
    }
    
     /*
    private func validateValueType(of option: BoundOption) throws {
        if let valueType = option.definition.convertibleToType {
            if valueType.init(argumentValue: option.value) == nil {
                throw CommandLineError.optionValueNotConvertibleToType(option.definition, type: valueType, value: option.value)
            }
        }
    }
    
    private func validateValueType(of input: BoundInput) throws {
        if let valueType = input.definition.convertibleToType {
            if valueType.init(argumentValue: input.value) == nil {
                throw CommandLineError.inputValueNotConvertibleToType(input.definition, type: valueType, value: input.value)
            }
        }
    }
     */
}


