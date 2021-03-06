
import Foundation

enum ParserState {
    case command
    case parsedSubcommand(Command)
    case parsedFlag(Flag)
    case parsedOption(Option)
    case parsedOptionValue(Option, String)
    case parsedInput(Input, String)
    case failure(CommandLineError)
    case success(ParserContext)
}

enum ParserEvent {
    case scannedSubcommand(Command)
    case scannedFlag(Flag)
    case scannedOption(Option)
    case scannedOptionValue(Option, String)
    case scannedInput(Input, String)
    case scannedInvalidFlagOrOption
    case scannedHelpFlag(Command?)
    case scannedUnexpectedArgument
    case errorWasThrown(CommandLineError)
    case noMoreArguments
}

class ParserStateMachine {
    
    private(set) var state: ParserState
    
    private(set) var context: ParserContext
    
    weak var delegate: ParserStateMachineDelegate?
    
    var isInEndState: Bool {
        switch state {
        case .success(_), .failure(_):
            return true
        default:
            return false
        }
    }
    
    var isNotInEndState: Bool {
        return !isInEndState
    }
    
    init(initialState: ParserState = .command, context: ParserContext) {
        state = initialState
        self.context = context
    }
    
    func fireEvent(_ event: ParserEvent, _ argument: String?) {
        guard let newState = delegate?.stateToTransitionTo(from: state,
                                                           dueTo: event,
                                                           argument: argument,
                                                           context: context,
                                                           stateMachine: self) else {
                                                            return
        }
        
        delegate?.willTransition(from: state,
                                 to: newState,
                                 dueTo: event,
                                 argument: argument,
                                 context: context,
                                 stateMachine: self)
        let oldState = state
        state = newState
        delegate?.didTransition(from: oldState,
                                to: state,
                                dueTo: event,
                                argument: argument,
                                context: context,
                                stateMachine: self)
    }
}

protocol ParserStateMachineDelegate: class {
    
    /// Return state to transition to from the current state given an event.
    /// Return nil to not trigger a transition.
    /// Return the from state for a loopback transition to itself.
    func stateToTransitionTo(from state: ParserState,
                             dueTo event: ParserEvent,
                             argument: String?,
                             context: ParserContext,
                             stateMachine: ParserStateMachine) -> ParserState?
    
    func willTransition(from state: ParserState,
                        to newState: ParserState,
                        dueTo event: ParserEvent,
                        argument: String?,
                        context: ParserContext,
                        stateMachine: ParserStateMachine)
    
    func didTransition(from state: ParserState,
                       to newState: ParserState,
                       dueTo event: ParserEvent,
                       argument: String?,
                       context: ParserContext,
                       stateMachine: ParserStateMachine)
}
