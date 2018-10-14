
import Foundation
import EditLine

class LineEditor {
    
    init() {
        lineEditorCreate()
    }
    
    deinit {
        lineEditorDestroy()
    }
    
    func readLine() -> String? {
        guard let cString = lineEditorReadLine() else {
            return nil
        }
        guard let nsString = NSString(cString: cString, encoding: String.Encoding.utf8.rawValue) else {
            return nil
        }
        let string = nsString as String
        return string
    }
    
    func reset() {
        lineEditorReset()
    }
}
