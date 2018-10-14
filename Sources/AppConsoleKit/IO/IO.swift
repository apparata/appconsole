//
//  Copyright © 2018 Apparata AB. All rights reserved.
//

import Foundation

public protocol InputHandle {
    func readData() -> Data?
    func readDataToEndOfFile() -> Data?
    func readData(ofLength length: Int) -> Data?
    func read() -> String?
    func readToEndOfFile() -> String?
    func read(length: Int) -> String?
    func close()
}

public protocol OutputHandle {
    func write(_ data: Data)
    func write(_ string: String)
    func writeLine(_ string: String)
    func flush()
    func close()
}

public protocol IO {
    var `in`: InputHandle { get }
    var out: OutputHandle { get }
    var error: OutputHandle { get }
}

public protocol WrapsFileHandle {
    var fileHandle: FileHandle { get }
}

// MARK: - Standard I/O

public final class StandardInput: InputHandle, WrapsFileHandle {
    
    public let fileHandle = FileHandle.standardInput
    
    public func readData() -> Data? {
        let data = fileHandle.availableData
        if data.isEmpty {
            return nil
        }
        return data
    }
    
    public func readDataToEndOfFile() -> Data? {
        let data = fileHandle.readDataToEndOfFile()
        if data.isEmpty {
            return nil
        }
        return data
    }
    
    public func readData(ofLength length: Int) -> Data? {
        let data = fileHandle.readData(ofLength: length)
        if data.isEmpty {
            return nil
        }
        return data
    }
    
    public func read() -> String? {
        return dataToString(readData())
    }
    
    public func readToEndOfFile() -> String? {
        return dataToString(readDataToEndOfFile())
    }
    
    public func read(length: Int) -> String? {
        return dataToString(readData(ofLength: length))
    }
    
    public func close() {
        fileHandle.closeFile()
    }
    
    private func dataToString(_ data: Data?) -> String? {
        guard let data = data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}

public class StandardBaseOutput: OutputHandle, WrapsFileHandle {
    
    public let fileHandle: FileHandle
    
    init(fileHandle: FileHandle) {
        self.fileHandle = fileHandle
    }
    
    public func write(_ data: Data) {
        fileHandle.write(data)
    }
    
    public func write(_ string: String) {
        guard let data = string.data(using: .utf8) else {
            fatalError("String could not be encoded as UTF-8.")
        }
        fileHandle.write(data)
    }
    
    public func writeLine(_ string: String) {
        write(string)
        write("\n")
    }
    
    public func flush() {
        fileHandle.synchronizeFile()
    }
    
    public func close() {
        fileHandle.closeFile()
    }
}

public final class StandardOutput: StandardBaseOutput {
    
    init() {
        super.init(fileHandle: FileHandle.standardOutput)
    }
}

public final class StandardError: StandardBaseOutput {

    init() {
        super.init(fileHandle: FileHandle.standardError)
    }
}

public final class StandardIO: IO {
    public let `in`: InputHandle = StandardInput()
    public let out: OutputHandle = StandardOutput()
    public let error: OutputHandle = StandardError()
}



