import Foundation
import Logger

public class ShellProcessStore {
    public static let shared = ShellProcessStore()

    private var processes: Set<Process> = []
    private let lock = UnfairLock()

    public func interruptRunning() {
        lock.perform {
            for process in processes {
                process.interrupt()
                process.waitUntilExit()
            }
        }
    }

    func add(_ process: Process) {
        lock.perform { _ = processes.insert(process) }
    }

    func remove(_ process: Process) {
        lock.perform { _ = processes.remove(process) }
    }
}

open class Shell {
    private let logger: ContextualLogger

    public init(logger: Logger) {
        self.logger = logger.contextualized(with: "shell")
    }

    @discardableResult
    open func exec(_ args: [String]) throws -> String {
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
    open func execStatus(_ args: [String]) throws -> Int32 {
        let (status, _, _) = try exec(args, captureOutput: false)
        return status
    }

    // MARK: - Private

    private func exec(
        _ args: [String],
        captureOutput: Bool = true
    ) throws -> (Int32, String, String) {
        let launchPath: String
        let newArgs: [String]

        if let cmd = args.first, cmd.hasPrefix("/") {
            launchPath = cmd
            newArgs = Array(args.dropFirst())
        } else {
            launchPath = "/usr/bin/env"
            newArgs = args
        }

        let process = Process()
        process.launchPath = launchPath
        process.arguments = newArgs

        logger.debug("\(launchPath) \(newArgs.joined(separator: " "))")
        ShellProcessStore.shared.add(process)

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
                ShellProcessStore.shared.remove(process)
                throw PeripheryError.shellOutputEncodingFailed(
                    cmd: launchPath,
                    args: newArgs,
                    encoding: .utf8
                )
            }
            standardOutput = stdoutStr
        }

        if let stderrData = try stderrPipe?.fileHandleForReading.readToEnd() {
            guard let stderrStr = String(data: stderrData, encoding: .utf8)
            else {
                ShellProcessStore.shared.remove(process)
                throw PeripheryError.shellOutputEncodingFailed(
                    cmd: launchPath,
                    args: newArgs,
                    encoding: .utf8
                )
            }
            standardError = stderrStr
        }

        #if os(Linux)
            // Workaround for https://github.com/swiftlang/swift-corelibs-foundation/issues/5153
            let semaphore = DispatchSemaphore(value: 0)
            process.terminationHandler = { _ in semaphore.signal() }
            semaphore.wait()
        #else
            process.waitUntilExit()
        #endif

        ShellProcessStore.shared.remove(process)
        return (process.terminationStatus, standardOutput, standardError)
    }
}
