import Foundation

open class Shell {
    private var tasks: Set<Process> = []
    private var tasksQueue = DispatchQueue(label: "Shell.tasksQueue")

    private let environment: [String: String]
    private let logger: ContextualLogger

    public convenience init(logger: Logger) {
        self.init(environment: ProcessInfo.processInfo.environment, logger: logger)
    }

    public required init(environment: [String: String], logger: Logger) {
        self.environment = environment
        self.logger = logger.contextualized(with: "shell")
    }

    public func interruptRunning() {
        tasksQueue.sync {
            for task in tasks {
                task.interrupt()
                task.waitUntilExit()
            }
        }
    }

    lazy var pristineEnvironment: [String: String] = {
        let shell = environment["SHELL"] ?? "/bin/bash"
        guard let pristineEnv = try? exec([shell, "-lc", "env"], environment: [:]).1 else {
            return environment
        }

        var newEnv = pristineEnv.trimmed
            .split(separator: "\n").map { line -> (String, String) in
                let pair = line.split(separator: "=", maxSplits: 1)
                return (String(pair.first ?? ""), String(pair.last ?? ""))
            }
            .reduce(into: [String: String]()) { result, pair in
                result[pair.0] = pair.1
            }

        let preservedKeys = ["TERM", "PATH", "DEVELOPER_DIR", "SSH_AUTH_SOCK"]
        for key in preservedKeys {
            if let value = environment[key] {
                newEnv[key] = value
            }
        }

        return newEnv
    }()

    @discardableResult
    open func exec(
        _ args: [String],
        stderr: Bool = true
    ) throws -> String {
        let env = environment
        let (status, output) = try exec(args, environment: env, stderr: stderr)

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
        let env = environment
        let (status, _) = try exec(args, environment: env, stderr: stderr, captureOutput: false)
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

        let task = Process()
        task.launchPath = launchPath
        task.environment = environment
        task.arguments = newArgs

        logger.debug("\(launchPath) \(newArgs.joined(separator: " "))")
        tasksQueue.sync { _ = tasks.insert(task) }

        var outputPipe: Pipe?

        if captureOutput {
            outputPipe = Pipe()
            task.standardOutput = outputPipe
            task.standardError = stderr ? outputPipe : nil
        }

        task.launch()

        var output = ""

        if let outputPipe,
           let outputData = try outputPipe.fileHandleForReading.readToEnd()
        {
            guard let str = String(data: outputData, encoding: .utf8) else {
                tasksQueue.sync { _ = tasks.remove(task) }
                throw PeripheryError.shellOutputEncodingFailed(
                    cmd: launchPath,
                    args: newArgs,
                    encoding: .utf8
                )
            }
            output = str
        }

        task.waitUntilExit()
        tasksQueue.sync { _ = tasks.remove(task) }
        return (task.terminationStatus, output)
    }
}
