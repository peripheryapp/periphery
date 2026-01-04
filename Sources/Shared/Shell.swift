import Foundation
import Logger
import Synchronization

final class ShellProcessStore: Sendable {
    private let processes = Mutex<Set<Process>>([])

    func interruptRunning() {
        processes.withLock { processes in
            for process in processes {
                process.interrupt()
                process.waitUntilExit()
            }
        }
    }

    func add(_ process: Process) {
        processes.withLock { _ = $0.insert(process) }
    }

    func remove(_ process: Process) {
        processes.withLock { _ = $0.remove(process) }
    }
}

public protocol Shell: Sendable {
    @discardableResult
    func exec(_ args: [String]) throws -> String
    func execStatus(_ args: [String]) throws -> Int32
}

public final class ShellImpl: Shell {
    private let logger: ContextualLogger
    private let store: ShellProcessStore
    private let signalSource: DispatchSourceSignal

    public required init(logger: Logger, sigintHandler: @escaping () -> Void = {}) {
        self.logger = logger.contextualized(with: "shell")
        store = ShellProcessStore()

        signal(SIGINT, SIG_IGN)
        signalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .global())
        signalSource.setEventHandler { [store] in
            sigintHandler()
            store.interruptRunning()
            exit(0)
        }
        signalSource.resume()
    }

    @discardableResult
    public func exec(_ args: [String]) throws -> String {
        let (status, stdout, stderr) = try exec(args)

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
    public func execStatus(_ args: [String]) throws -> Int32 {
        let (status, _, _) = try exec(args, captureOutput: false)
        return status
    }

    // MARK: - Private

    private func exec(
        _ cmd: [String],
        captureOutput: Bool = true
    ) throws -> (Int32, String, String) {
        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", cmd.joined(separator: " ")]

        logger.debug("\(cmd.joined(separator: " "))")
        store.add(process)

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
                store.remove(process)
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
                store.remove(process)
                throw PeripheryError.shellOutputEncodingFailed(
                    cmd: cmd,
                    encoding: .utf8
                )
            }
            standardError = stderrStr
        }

        process.waitUntilExit()
        store.remove(process)
        return (process.terminationStatus, standardOutput, standardError)
    }
}
