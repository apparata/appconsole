//
//  Copyright © 2018 Apparata AB. All rights reserved.
//

import Foundation

class AppConsoleCommands {
    
    static func makeCommands() -> [Command] {
        
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
            ]),
            
            Command(name: "version",
                    description: "Prints the version.",
                    arguments: []),
            
            Command(name: "vibrate",
                    description: "Make the device vibrate.",
                    arguments: []),
            
            Command(name: "shake",
                    description: "Make the screen shake.",
                    arguments: []),
            
            Command(name: "screenshot",
                    description: "Take a screenshot.",
                    arguments: []),
            
            Command(name: "selectTab",
                    description: "Select a tab",
                    arguments: [
                        Input("index",
                              type: .int,
                              isOptional: false,
                              validationRegex: "^\\d+$",
                              description: "Tab index to select")
            ]),
            
            Command(name: "upload",
                    description: "Upload a photo",
                    arguments: [
                        Input("photo",
                              type: .file,
                              isOptional: false,
                              validationRegex: "^.*\\.jpg$",
                              description: "Path to photo.")
                ]),
        ]
        
        return commands
    }    
}
