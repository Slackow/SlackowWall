//
//  main.swift
//  PacemanWrapper
//
//  Created by Andrew on 5/28/25.
//

import Darwin
import Foundation

var childProcess: Process?

// MARK: – Helpers
func javaHome() -> String? {
    let proc = Process()
    proc.executableURL = URL(filePath: "/usr/libexec/java_home")
    let pipe = Pipe()
    proc.standardOutput = pipe
    do {
        try proc.run()
        proc.waitUntilExit()
        guard proc.terminationStatus == 0 else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    } catch { return nil }
}

func defaultJarPath() -> String {
    // Compute ../Contents/Resources/Jars/paceman-tracker-*.jar relative to this binary
    let execURL = URL(filePath: CommandLine.arguments[0]).resolvingSymlinksInPath()
    let bundleURL = execURL.deletingLastPathComponent().deletingLastPathComponent()  // …/MacOS → …/Contents
    return bundleURL.appending(path: "Resources/Jars/paceman-tracker-0.7.1.jar").path
}

// MARK: – Resolve paths
let parentPID = getppid()
let javaBin =
    javaHome()?.appending("/bin/java").trimmingCharacters(in: .whitespacesAndNewlines) ?? "java"
let jarPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultJarPath()

// MARK: – Signal forwarding
func installSignalHandlers() {
    let handler: @convention(c) (Int32) -> Void = { _ in
        if let proc = childProcess, proc.isRunning {
            proc.terminate()
            proc.waitUntilExit()
        }
        exit(0)
    }
    signal(SIGTERM, handler)
    signal(SIGINT, handler)
    signal(SIGQUIT, handler)
    signal(SIGHUP, handler)
}

// MARK: – Launch JVM
let child = Process()
childProcess = child
installSignalHandlers()
child.executableURL = URL(filePath: javaBin)
child.arguments = ["-Dapple.awt.UIElement=true", "-jar", jarPath, "--nogui"]
child.standardOutput = FileHandle.standardOutput
child.standardError = FileHandle.standardError

do { try child.run() } catch {
    fputs("Wrapper: failed to start JVM – \(error)\n", stderr)
    exit(1)
}

// MARK: – Parent monitor
DispatchQueue.global().async {
    while true {
        if kill(parentPID, 0) != 0 {  // parent gone
            child.terminate()
            child.waitUntilExit()
            exit(child.terminationStatus)
        }
        sleep(1)
    }
}

child.waitUntilExit()
exit(child.terminationStatus)
