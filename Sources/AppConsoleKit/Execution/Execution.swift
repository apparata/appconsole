
import Foundation

public class Execution {
    
    /// Starts the main run loop.
    public static func runUntilTerminated(interruptHandler: (() -> Void)? = nil) {
        RunLoop.main.run()
    }
    
    /// Installs an interrupt signal handler. Use it to clean up before exit.
    public static func installInterruptSignalHandler(shouldExit: Bool = true, handler: (() -> Void)?) -> DispatchSourceSignal {
        
        let source = DispatchSource.makeSignalSource(signal: SIGINT, queue: DispatchQueue.main)
        source.setEventHandler {
            handler?()
            if shouldExit {
                exit(0)
            }
        }
        
        // Ignore default handler.
        signal(SIGINT, SIG_IGN)
        
        source.resume()
        
        return source
    }
    
    static let isDebuggerAttached: Bool = {
        var info = kinfo_proc()
        var mib : [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        let junk = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        assert(junk == 0, "sysctl failed")
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }()
}
