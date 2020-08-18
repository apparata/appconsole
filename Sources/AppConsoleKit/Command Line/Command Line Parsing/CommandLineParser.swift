//
//  Copyright © 2018 Apparata AB. All rights reserved.
//

import Foundation

public final class CommandLineParser {
    
    private let command: Command
    private let allCommands: [Command]
    
    public init(command: Command, allCommands: [Command]) {
        self.command = command
        self.allCommands = allCommands
    }
        
    /// Parse command line arguments.
    ///
    /// - parameter arguments: Arguments, without the executable argument.
    public func parse(_ arguments: [String]) throws -> RunCommandRequest {
        
        if arguments.isEmpty {
            if command.hasSubcommands || command.argumentCount > 1 {
                throw CommandLineError.usageRequested(command, nil)
            }
        }
        
        let resultingState = runStateMachine(for: arguments)
        
        switch resultingState {
        case .success(let context):
            var helpRequested: Bool = false
            var helpCommand: Command = context.commands[0]

            let commands = context.commands.map { $0.name }

            for (index, command) in context.commands.enumerated() {
                if command.name == "help" {
                    helpRequested = true
                    if let (_, value) = context.arguments.first, case let .string(string) = value {
                        if index == 0, let rootLevelCommand = allCommands.first(where: { $0.name == string }) {
                            helpCommand = rootLevelCommand
                        } else if let subcommand = helpCommand.context.subcommands.first(where: { $0.name == string }) {
                            helpCommand = subcommand
                        }
                    }
                } else {
                    helpCommand = command
                }
            }
            
            var arguments: [String: ArgumentValue] = [:]
            for (argument, value) in context.arguments {
                arguments[argument.name] = value
                if argument.name == "help" {
                    helpRequested = true
                    helpCommand = context.commands.last ?? helpCommand
                }
            }
            
            if helpRequested {
                throw CommandLineError.usageRequested(self.command, helpCommand)
            }
            
            let command = RunCommandRequest(commands: commands, arguments: arguments)
            
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
        case .subcommands:
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
                    case .subcommands:
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
                    
                case .parsedFlag, .parsedOptionValue:
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
        case .subcommands:
            if ["-h", "--help"].contains(string) {
                return Flag("help", short: "h", description: "Show this help text.")
            }
            return nil
        case .arguments(let flags, _, _, _):
            if ["-h", "--help"].contains(string) {
                return Flag("help", short: "h", description: "Show this help text.")
            }
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
        case .subcommands:
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
            
        case (.parsedSubcommand, .noMoreArguments):
            return .success(context)
        case (.parsedSubcommand, .scannedSubcommand(let subcommand)):
            return .parsedSubcommand(subcommand)
        case (.parsedSubcommand, .scannedFlag(let flag)):
            return .parsedFlag(flag)
        case (.parsedSubcommand, .scannedOption(let option)):
            return .parsedOption(option)
        case (.parsedSubcommand, .scannedInput(let input, let value)):
            return .parsedInput(input, value)
        case (.parsedSubcommand, .scannedInvalidFlagOrOption):
            return .failure(argument.map { .invalidFlagOrOption($0) } ?? .unexpectedError)
        case (.parsedSubcommand, .scannedHelpFlag(let subcommand)):
            return .failure(.usageRequested(command, subcommand))
        case (.parsedSubcommand, _):
            return .failure(argument.map { .unexpectedArgument($0) } ?? .unexpectedError)
            
        case (.parsedFlag, .noMoreArguments):
            return .success(context)
        case (.parsedFlag, .scannedFlag(let flag)):
            return .parsedFlag(flag)
        case (.parsedFlag, .scannedOption(let option)):
            return .parsedOption(option)
        case (.parsedFlag, .scannedInput(let input, let value)):
            return .parsedInput(input, value)
        case (.parsedFlag, .scannedInvalidFlagOrOption):
            return .failure(argument.map { .invalidFlagOrOption($0) } ?? .unexpectedError)
        case (.parsedFlag, .scannedHelpFlag(let subcommand)):
            return .failure(.usageRequested(command, subcommand))
        case (.parsedFlag, _):
            return .failure(argument.map { .unexpectedArgument($0) } ?? .unexpectedError)
            
        case (.parsedOption, .scannedOptionValue(let option, let value)):
            return .parsedOptionValue(option, value)
        case (.parsedOption(let option), _):
            return .failure(.missingOptionValue(option))
            
        case (.parsedOptionValue, .noMoreArguments):
            return .success(context)
        case (.parsedOptionValue, .scannedFlag(let flag)):
            return .parsedFlag(flag)
        case (.parsedOptionValue, .scannedOption(let option)):
            return .parsedOption(option)
        case (.parsedOptionValue, .scannedInput(let input, let value)):
            return .parsedInput(input, value)
        case (.parsedOptionValue, .scannedInvalidFlagOrOption):
            return .failure(argument.map { .invalidFlagOrOption($0) } ?? .unexpectedError)
        case (.parsedOptionValue, .scannedHelpFlag(let subcommand)):
            return .failure(.usageRequested(command, subcommand))
        case (.parsedOptionValue, _):
            return .failure(argument.map { .unexpectedArgument($0) } ?? .unexpectedError)
            
        case (.parsedInput, .noMoreArguments):
            return .success(context)
        case (.parsedInput, .scannedInput(let input, let value)):
            return .parsedInput(input, value)
        case (.parsedInput, _):
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
