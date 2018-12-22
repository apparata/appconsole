import XCTest
@testable import AppConsoleKit

final class AppConsoleKitTests: XCTestCase {
    
    func testExample() {
        try! "Banana".data(using: .utf8)?.write(to: URL(fileURLWithPath: "/tmp/banana.txt"))
        let parsedCommand = evaluateCommandLine("stuff process -v --passes 8 /tmp/banana.txt")
        dump(parsedCommand)
    }
    
    private func evaluateCommandLine(_ commandLine: String) -> AppCommand {
        let commandLineProcessor = CommandLineProcessor()
        let commands = makeCommands()
        do {
            let parsedCommand = try commandLineProcessor.evaluate(commandLine, commands: commands)
            return parsedCommand
        } catch {
            XCTAssert(false, error.localizedDescription)
        }
        fatalError()
    }
    
    private func makeCommands() -> [Command] {
        
        let commands = [
            
            Command(name: "stuff",
                    description: "Command that does stuff.",
                    subcommands: [
                Command(name: "process",
                        description: "This command processes stuff.",
                        isLastInputVariadic: false,
                        arguments: [
                    Flag("verbose", short: "v", description: "Verbose output from command."),
                    Option("passes",
                           short: "p",
                           type: .int,
                           isMultipleAllowed: false,
                           validationRegex: "^\\d+$",
                           description: "The number of processing passes."),
                    Input("textFile",
                          type: .file,
                          isOptional: false,
                          validationRegex: "^.*\\.txt$",
                          description: "The text file to process.")
                ])
            ])
        
        ]

        return commands
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
