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
    private let environment: [String: String]
    private let logger: ContextualLogger

    public convenience init(logger: Logger) {
        self.init(environment: ProcessInfo.processInfo.environment, logger: logger)
    }

    public required init(environment: [String: String], logger: Logger) {
        self.environment = environment
        self.logger = logger.contextualized(with: "shell")
    }

    @discardableResult
    open func exec(
        _ args: [String],
        stderr: Bool = true
    ) throws -> String {
        let (status, output) = try exec(args, environment: environment, stderr: stderr)

        if status == 0 {
            return output
        }

        throw PeripheryError.shellCommandFailed(
            cmd: args,
            status: status,
            output: output
        )
    }

    @discardableResult
    open func execStatus(
        _ args: [String],
        stderr: Bool = true
    ) throws -> Int32 {
        let (status, _) = try exec(args, environment: environment, stderr: stderr, captureOutput: false)
        return status
    }

    // MARK: - Private

    private func exec(
        _ args: [String],
        environment: [String: String],
        stderr: Bool = false,
        captureOutput: Bool = true
    ) throws -> (Int32, String) {
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
        process.environment = environment
        process.arguments = newArgs

        logger.debug("\(launchPath) \(newArgs.joined(separator: " "))")
        ShellProcessStore.shared.add(process)

        var outputPipe: Pipe?

        if captureOutput {
            outputPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = stderr ? outputPipe : nil
        }

        process.launch()

        var output = ""

        if let outputPipe,
           let outputData = try outputPipe.fileHandleForReading.readToEnd()
        {
            guard let str = String(data: outputData, encoding: .utf8) else {
                ShellProcessStore.shared.remove(process)
                throw PeripheryError.shellOutputEncodingFailed(
                    cmd: launchPath,
                    args: newArgs,
                    encoding: .utf8
                )
            }
            output = str
        }

        process.waitUntilExit()
        ShellProcessStore.shared.remove(process)
        return (process.terminationStatus, output)
    }
}
