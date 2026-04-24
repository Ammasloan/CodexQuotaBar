import Darwin
import Foundation

enum InstanceManager {
    static func terminateOtherInstances() {
        let currentPID = getpid()

        for pid in otherProcessIDs(currentPID: currentPID) {
            kill(pid_t(pid), SIGTERM)
        }
    }

    static func otherInstanceCount() -> Int {
        otherProcessIDs(currentPID: getpid()).count
    }

    private static func otherProcessIDs(currentPID: Int32) -> [Int32] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        process.arguments = ["-x", ProcessInfo.processInfo.processName]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return []
        }

        guard process.terminationStatus == 0 || process.terminationStatus == 1 else {
            return []
        }

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard let text = String(data: data, encoding: .utf8) else {
            return []
        }

        return text
            .split(whereSeparator: \.isNewline)
            .compactMap { Int32($0) }
            .filter { $0 != currentPID }
    }
}
