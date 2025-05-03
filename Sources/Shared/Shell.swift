import Foundation
import Logger

public actor ShellProcessStore {
    public static let shared = ShellProcessStore()

    private var processes: Set<Process> = []

    public func interruptRunning() {
        for process in processes {
            process.interrupt()
            process.waitUntilExit()
        }
    }

    func add(_ process: Process) async {
        _ = processes.insert(process)
    }

    func remove(_ process: Process) async {
        _ = processes.remove(process)
    }
}

open class Shell {
    private let logger: ContextualLogger

    public required init(logger: Logger) {
        self.logger = logger.contextualized(with: "shell")
    }

    @discardableResult
    open func exec(_ args: [String]) async throws -> String {
        let (status, stdout, stderr) = try await exec(args)

        if status == 0 {
            return stdout
        }

        throw PeripheryError.shellCommandFailed(
            cmd: args,
            status: status,
            output: [stdout, stderr].filter { !$0.isEmpty }.joined(separator: "\n").trimmed
        )
    }

    @discardableResult
    open func execStatus(_ args: [String]) async throws -> Int32 {
        let (status, _, _) = try await exec(args, captureOutput: false)
        return status
    }

    // MARK: - Private

    private func exec(
        _ cmd: [String],
        captureOutput: Bool = true
    ) async throws -> (Int32, String, String) {
        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", cmd.joined(separator: " ")]

        logger.debug("\(cmd.joined(separator: " "))")
        await ShellProcessStore.shared.add(process)

        var stdoutPipe: Pipe?
        var stderrPipe: Pipe?

        if captureOutput {
            stdoutPipe = Pipe()
            stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe
        }

        process.launch()

        var standardOutput = ""
        var standardError = ""

        if let stdoutData = try stdoutPipe?.fileHandleForReading.readToEnd() {
            guard let stdoutStr = String(data: stdoutData, encoding: .utf8)
            else {
                await ShellProcessStore.shared.remove(process)
                throw PeripheryError.shellOutputEncodingFailed(
                    cmd: cmd,
                    encoding: .utf8
                )
            }
            standardOutput = stdoutStr
        }

        if let stderrData = try stderrPipe?.fileHandleForReading.readToEnd() {
            guard let stderrStr = String(data: stderrData, encoding: .utf8)
            else {
                await ShellProcessStore.shared.remove(process)
                throw PeripheryError.shellOutputEncodingFailed(
                    cmd: cmd,
                    encoding: .utf8
                )
            }
            standardError = stderrStr
        }

        process.waitUntilExit()
        await ShellProcessStore.shared.remove(process)
        return (process.terminationStatus, standardOutput, standardError)
    }
}
