//
//  CLI.swift
//  Fuji
//
//  Created by Arsile on 25/07/26.
//

import Foundation

enum CLI {
    static let executablePath: String = {
        let knownPaths = [
            "/usr/local/bin/container",      // Intel Mac / Homebrew default
            "/opt/homebrew/bin/container",   // Apple Silicon Homebrew
            "\(NSHomeDirectory())/.local/bin/container" // User-local installs"
        ]
        
        for path in knownPaths {
                    if FileManager.default.isExecutableFile(atPath: path) {
                        return path
                    }
                }
                
                // 2. Fallback: Use `which` to search the full PATH
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
                process.arguments = ["container"]
                
                let pipe = Pipe()
                process.standardOutput = pipe
                
                do {
                    try process.run()
                    process.waitUntilExit()
                    
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !path.isEmpty {
                        return path
                    }
                } catch {
                    print("⚠️ Failed to resolve container path via 'which': \(error)")
                }
                
                // 3. Last resort fallback
                return "/usr/local/bin/container"
    }()
    
    static func run(arguments: [String]) async throws -> String {
        return try await withCheckedThrowingContinuation {continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = arguments
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            
            process.terminationHandler = { proc in
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                
                if proc.terminationStatus != 0 {
                    let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    continuation.resume(throwing: NSError(domain: "CLIError", code: Int(proc.terminationStatus), userInfo: [NSLocalizedDescriptionKey: errorString]))
                } else {
                    let outputString = String(data: outputData, encoding: .utf8) ?? ""
                    continuation.resume(returning: outputString)
                }
            }
            
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
