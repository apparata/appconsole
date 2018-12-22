
import Foundation
import AppConsoleKit

func printUsage() -> Never {
    print("USAGE: appconsole [-v] <instanceName>")
    exit(1)
}

func parseArguments(_ arguments: [String]) -> (Bool, String) {
    guard !arguments.isEmpty else {
        printUsage()
    }
    
    var verbose: Bool = false
    
    let secondArgument = CommandLine.arguments[1]
    if secondArgument == "-v" || secondArgument == "--verbose" {
        verbose = true
    }

    let appInstanceName = arguments[verbose ? 1 : 0]
    
    return (verbose, appInstanceName)
}

let (verbose, appInstanceName) = parseArguments(Array(CommandLine.arguments.dropFirst()))

let appConsole = AppConsole(instanceName: appInstanceName, verbose: verbose)

appConsole.start()

Execution.runUntilTerminated(interruptHandler: {
    appConsole.stop()
})

