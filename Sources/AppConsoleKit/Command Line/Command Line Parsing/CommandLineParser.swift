//
//  Copyright © 2018 Apparata AB. All rights reserved.
//

import Foundation

public final class CommandLineParser {
    
    private let command: Command
    
    public init(command: Command) {
        self.command = command
    }
        
    /// Parse command line arguments.
    ///
    /// - parameter arguments: Arguments, without the executable argument.
    public func parse(_ arguments: [String]) throws -> AppCommand {
        
        if arguments.isEmpty {
            if command.hasSubcommands || command.argumentCount > 1 {
                throw CommandLineError.usageRequested(command, nil)
            }
        }
        
        let resultingState = runStateMachine(for: arguments)
        
        switch resultingState {
        case .success(let context):
            var helpRequested: Bool = false

            let commands = context.commands.map { $0.name }

            var arguments: [String: AppArgument] = [:]
            for (argument, value) in context.arguments {
                arguments[argument.name] = value
                if argument.name == "help" {
                    helpRequested = true
                }
            }
            
            if helpRequested, let helpCommand = context.commands.last {
                throw CommandLineError.usageRequested(self.command, helpCommand)
            }
            
            let command = AppCommand(commands: commands, arguments: arguments)
            
            return command
        case .failure(let error):
            throw error
        default:
            throw CommandLineError.unexpectedError
        }
    }
    
    private func runStateMachine(for arguments: [String]) -> ParserState {
        
        let context = ParserContext(command: command)
        
        let stateMachine = ParserStateMachine(context: context)
        stateMachine.delegate = self
        
        var args = arguments
        
        var currentCommand: Command = command
        var remainingInputs: [Input] = []
        
        switch currentCommand.context {
        case .subcommands(_):
            remainingInputs = []
        case .arguments(_, _, let inputs, _):
            remainingInputs = inputs
        }
        
        while stateMachine.isNotInEndState {
            if args.isEmpty {
                stateMachine.fireEvent(.noMoreArguments, nil)
            } else {
                let argument = args.removeFirst()
                
                switch stateMachine.state {
                    
                case .command:
                    if isFlagOrOption(argument) {
                        if let flag = getFlag(correspondingTo: argument, command: currentCommand) {
                            // Special treatment of the -h / --help flag.
                            if flag.name == "help" {
                                stateMachine.fireEvent(.scannedHelpFlag(currentCommand), argument)
                            } else {
                                stateMachine.fireEvent(.scannedFlag(flag), argument)
                            }
                        } else if let option = getOption(correspondingTo: argument, command: currentCommand) {
                            stateMachine.fireEvent(.scannedOption(option), argument)
                        } else {
                            stateMachine.fireEvent(.scannedInvalidFlagOrOption, argument)
                        }
                    } else if let subcommand = getSubcommand(correspondingTo: argument, command: currentCommand) {
                        stateMachine.fireEvent(.scannedSubcommand(subcommand), argument)
                    } else if let input = remainingInputs.first {
                        stateMachine.fireEvent(.scannedInput(input, argument), argument)
                        if remainingInputs.count != 1 /*|| !commandDefinition.isLastInputVariadic*/ {
                            remainingInputs.removeFirst()
                        }
                    } else {
                        stateMachine.fireEvent(.scannedUnexpectedArgument, argument)
                    }
                    
                case .parsedSubcommand(let parsedSubcommand):
                    currentCommand = parsedSubcommand
                    switch currentCommand.context {
                    case .subcommands(_):
                        remainingInputs = []
                    case .arguments(_, _, let inputs, _):
                        remainingInputs = inputs
                    }
                    if isFlagOrOption(argument) {
                        if let flag = getFlag(correspondingTo: argument, command: currentCommand) {
                            // Special treatment of the -h / --help flag.
                            if flag.name == "help" {
                                stateMachine.fireEvent(.scannedHelpFlag(currentCommand), argument)
                            } else {
                                stateMachine.fireEvent(.scannedFlag(flag), argument)
                            }
                        } else if let option = getOption(correspondingTo: argument, command: currentCommand) {
                            stateMachine.fireEvent(.scannedOption(option), argument)
                        } else {
                            stateMachine.fireEvent(.scannedInvalidFlagOrOption, argument)
                        }
                    } else if let subcommand = getSubcommand(correspondingTo: argument, command: currentCommand) {
                        stateMachine.fireEvent(.scannedSubcommand(subcommand), argument)
                    } else if let input = remainingInputs.first {
                        stateMachine.fireEvent(.scannedInput(input, argument), argument)
                        if remainingInputs.count != 1 /*|| !commandDefinition.isLastInputVariadic*/ {
                            remainingInputs.removeFirst()
                        }
                    } else {
                        stateMachine.fireEvent(.scannedUnexpectedArgument, argument)
                    }
                    
                case .parsedFlag(_), .parsedOptionValue(_, _):
                    if isFlagOrOption(argument) {
                        if let flag = getFlag(correspondingTo: argument, command: currentCommand) {
                            // Special treatment of the -h / --help flag.
                            if flag.name == "help" {
                                stateMachine.fireEvent(.scannedHelpFlag(currentCommand), argument)
                            } else {
                                stateMachine.fireEvent(.scannedFlag(flag), argument)
                            }
                        } else if let option = getOption(correspondingTo: argument, command: currentCommand) {
                            stateMachine.fireEvent(.scannedOption(option), argument)
                        } else {
                            stateMachine.fireEvent(.scannedInvalidFlagOrOption, argument)
                        }
                    } else if let input = remainingInputs.first {
                        stateMachine.fireEvent(.scannedInput(input, argument), argument)
                        if remainingInputs.count != 1 /*|| !commandDefinition.isLastInputVariadic*/ {
                            remainingInputs.removeFirst()
                        }
                    } else {
                        stateMachine.fireEvent(.scannedUnexpectedArgument, argument)
                    }
                    
                case .parsedOption(let parsedOption):
                    if isFlagOrOption(argument) {
                        stateMachine.fireEvent(.scannedUnexpectedArgument, argument)
                    } else {
                        stateMachine.fireEvent(.scannedOptionValue(parsedOption, argument), argument)
                    }
                    
                case .parsedInput(_, _):
                    if isFlagOrOption(argument) {
                        stateMachine.fireEvent(.scannedUnexpectedArgument, argument)
                    } else if let input = remainingInputs.first {
                        stateMachine.fireEvent(.scannedInput(input, argument), argument)
                        if remainingInputs.count != 1 /*|| !commandDefinition.isLastInputVariadic*/ {
                            remainingInputs.removeFirst()
                        }
                    } else {
                        stateMachine.fireEvent(.scannedUnexpectedArgument, argument)
                    }
                    
                default:
                    return .failure(CommandLineError.unexpectedArgument(argument))
                }
            }
        }
        
        return stateMachine.state
    }
    
    private func isFlagOrOption(_ string: String) -> Bool {
        return string.starts(with: "-") || string.starts(with: "--")
    }
    
    private func getSubcommand(correspondingTo string: String, command: Command) -> Command? {
        switch command.context {
        case .subcommands(let subcommands):
            let subcommand = subcommands.first(where: { $0.name == string })
            return subcommand
        case .arguments(_, _, _, _):
            return nil
        }
    }
    
    private func getFlag(correspondingTo string: String, command: Command) -> Flag? {
        switch command.context {
        case .subcommands(_):
            return nil
        case .arguments(let flags, _, _, _):
            let flag = flags.first(where: {
                if "--\($0.name)" == string {
                    return true
                } else if "-\($0.short)" == string {
                    return true
                } else {
                    return false
                }
            })
            return flag
        }
    }
    
    private func getOption(correspondingTo string: String, command: Command) -> Option? {
        switch command.context {
        case .subcommands(_):
            return nil
        case .arguments(_, let options, _, _):
            let option = options.first(where: {
                if "--\($0.name)" == string {
                    return true
                } else if "-\($0.short)" == string {
                    return true
                } else {
                    return false
                }
            })
            return option
        }
    }
}

extension CommandLineParser: ParserStateMachineDelegate {
    
    func stateToTransitionTo(from state: ParserState,
                             dueTo event: ParserEvent,
                             argument: String?,
                             context: ParserContext,
                             stateMachine: ParserStateMachine) -> ParserState? {
        
        switch (state, event) {
            
        case (_, .errorWasThrown(let error)):
            return .failure(error)
            
        case (.command, .noMoreArguments):
            return .success(context)
        case (.command, .scannedSubcommand(let subcommand)):
            return .parsedSubcommand(subcommand)
        case (.command, .scannedFlag(let flag)):
            return .parsedFlag(flag)
        case (.command, .scannedOption(let option)):
            return .parsedOption(option)
        case (.command, .scannedInput(let input, let value)):
            return .parsedInput(input, value)
        case (.command, .scannedInvalidFlagOrOption):
            return .failure(argument.map { .invalidFlagOrOption($0) } ?? .unexpectedError)
        case (.command, .scannedHelpFlag(let subcommand)):
            return .failure(.usageRequested(command, subcommand))
        case (.command, _):
            return .failure(argument.map { .unexpectedArgument($0) } ?? .unexpectedError)
            
        case (.parsedSubcommand(_), .noMoreArguments):
            return .success(context)
        case (.parsedSubcommand(_), .scannedSubcommand(let subcommand)):
            return .parsedSubcommand(subcommand)
        case (.parsedSubcommand(_), .scannedFlag(let flag)):
            return .parsedFlag(flag)
        case (.parsedSubcommand(_), .scannedOption(let option)):
            return .parsedOption(option)
        case (.parsedSubcommand(_), .scannedInput(let input, let value)):
            return .parsedInput(input, value)
        case (.parsedSubcommand(_), .scannedInvalidFlagOrOption):
            return .failure(argument.map { .invalidFlagOrOption($0) } ?? .unexpectedError)
        case (.parsedSubcommand(_), .scannedHelpFlag(let subcommand)):
            return .failure(.usageRequested(command, subcommand))
        case (.parsedSubcommand(_), _):
            return .failure(argument.map { .unexpectedArgument($0) } ?? .unexpectedError)
            
        case (.parsedFlag(_), .noMoreArguments):
            return .success(context)
        case (.parsedFlag(_), .scannedFlag(let flag)):
            return .parsedFlag(flag)
        case (.parsedFlag(_), .scannedOption(let option)):
            return .parsedOption(option)
        case (.parsedFlag(_), .scannedInput(let input, let value)):
            return .parsedInput(input, value)
        case (.parsedFlag(_), .scannedInvalidFlagOrOption):
            return .failure(argument.map { .invalidFlagOrOption($0) } ?? .unexpectedError)
        case (.parsedFlag(_), .scannedHelpFlag(let subcommand)):
            return .failure(.usageRequested(command, subcommand))
        case (.parsedFlag(_), _):
            return .failure(argument.map { .unexpectedArgument($0) } ?? .unexpectedError)
            
        case (.parsedOption(_), .scannedOptionValue(let option, let value)):
            return .parsedOptionValue(option, value)
        case (.parsedOption(let option), _):
            return .failure(.missingOptionValue(option))
            
        case (.parsedOptionValue(_), .noMoreArguments):
            return .success(context)
        case (.parsedOptionValue(_), .scannedFlag(let flag)):
            return .parsedFlag(flag)
        case (.parsedOptionValue(_), .scannedOption(let option)):
            return .parsedOption(option)
        case (.parsedOptionValue(_), .scannedInput(let input, let value)):
            return .parsedInput(input, value)
        case (.parsedOptionValue(_), .scannedInvalidFlagOrOption):
            return .failure(argument.map { .invalidFlagOrOption($0) } ?? .unexpectedError)
        case (.parsedOptionValue(_), .scannedHelpFlag(let subcommand)):
            return .failure(.usageRequested(command, subcommand))
        case (.parsedOptionValue(_), _):
            return .failure(argument.map { .unexpectedArgument($0) } ?? .unexpectedError)
            
        case (.parsedInput(_), .noMoreArguments):
            return .success(context)
        case (.parsedInput(_), .scannedInput(let input, let value)):
            return .parsedInput(input, value)
        case (.parsedInput(_), _):
            return .failure(argument.map { .unexpectedArgument($0) } ?? .unexpectedError)
            
        default:
            return .failure(.unexpectedError)
        }
    }
    
    func willTransition(from state: ParserState,
                        to newState: ParserState,
                        dueTo event: ParserEvent,
                        argument: String?,
                        context: ParserContext,
                        stateMachine: ParserStateMachine) {
        
    }
    
    func didTransition(from state: ParserState,
                       to newState: ParserState,
                       dueTo event: ParserEvent,
                       argument: String?,
                       context: ParserContext,
                       stateMachine: ParserStateMachine) {
        
        do {
            switch newState {
                
            case .parsedSubcommand(let parsedSubcommand):
                try context.addSubcommand(parsedSubcommand)
                
            case .parsedFlag(let parsedFlag):
                try context.addFlag(parsedFlag)
                
            case .parsedOptionValue(let parsedOption, let value):
                if let pattern = parsedOption.validationRegex,
                    !isMatch(pattern, value) {
                    throw CommandLineError.invalidOptionValueFormat(parsedOption)
                }
                try context.addOption(parsedOption, stringValue: value)
                
            case .parsedInput(let parsedInput, let value):
                if let pattern = parsedInput.validationRegex,
                    !isMatch(pattern, value) {
                    throw CommandLineError.invalidInputValueFormat(parsedInput)
                }
                try context.addInput(parsedInput, stringValue: value)
                
            default:
                break
            }
        } catch let error as CommandLineError {
            stateMachine.fireEvent(.errorWasThrown(error), argument)
        } catch {
            stateMachine.fireEvent(.scannedUnexpectedArgument, argument)
        }
    }
    
    func isMatch(_ pattern: String, _ string: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matchCount = regex.numberOfMatches(in: string, options: [], range: NSMakeRange(0, string.count))
            return matchCount > 0
        } catch {
            return false
        }
    }
}
