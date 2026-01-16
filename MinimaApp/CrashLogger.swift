import Foundation
import os.log

/// "The Black Box"
/// Provides crash recovery, error logging, and optional telemetry.
/// Privacy-first: Logs stay on device unless user opts in.
public class CrashLogger {
    public static let shared = CrashLogger()
    
    private let logger = Logger(subsystem: "com.minima.app", category: "Error")
    private let logFileURL: URL
    
    private init() {
        // Store logs in app support directory
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let minimaDir = appSupport.appendingPathComponent("Minima")
        try? FileManager.default.createDirectory(at: minimaDir, withIntermediateDirectories: true)
        self.logFileURL = minimaDir.appendingPathComponent("crash.log")
    }
    
    /// Log an error
    public func logError(_ error: Error, context: String = "") {
        let message = "[\(Date())] [\(context)] \(error.localizedDescription)"
        logger.error("\(message)")
        appendToFile(message)
    }
    
    /// Log a warning
    public func logWarning(_ message: String) {
        logger.warning("\(message)")
        appendToFile("[WARN] \(message)")
    }
    
    /// Log info
    public func logInfo(_ message: String) {
        logger.info("\(message)")
    }
    
    /// Capture a fatal crash
    public func captureFatal(_ message: String) -> Never {
        logger.critical("FATAL: \(message)")
        appendToFile("[FATAL] \(message)")
        fatalError(message)
    }
    
    /// Setup crash handlers
    public func install() {
        NSSetUncaughtExceptionHandler { exception in
            CrashLogger.shared.appendToFile("[CRASH] \(exception.name): \(exception.reason ?? "Unknown")")
        }
        logInfo("CrashLogger installed.")
    }
    
    /// Get logs for support ticket
    public func exportLogs() -> String {
        return (try? String(contentsOf: logFileURL, encoding: .utf8)) ?? "No logs available."
    }
    
    /// Clear old logs
    public func clearLogs() {
        try? FileManager.default.removeItem(at: logFileURL)
    }
    
    private func appendToFile(_ message: String) {
        let data = (message + "\n").data(using: .utf8)!
        if FileManager.default.fileExists(atPath: logFileURL.path) {
            if let handle = try? FileHandle(forWritingTo: logFileURL) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            }
        } else {
            try? data.write(to: logFileURL)
        }
    }
}
