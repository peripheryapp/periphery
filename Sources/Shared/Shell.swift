import Foundation

final class ReadableStream {
    private let cmd: String
    private let args: [String]
    private let fileHandle: FileHandle
    private let task: Process
    private let encoding: String.Encoding
    private var output = ""
    private var didExit = false

    init(cmd: String, args: [String], fileHandle: FileHandle, task: Process, encoding: String.Encoding = .utf8) {
        self.cmd = cmd
        self.args = args
        self.fileHandle = fileHandle
        self.task = task
        self.encoding = encoding
    }

    func terminationStatus() throws -> Int32 {
        try waitUntilExit()
        return task.terminationStatus
    }

    func allOutput() throws -> String {
        try waitUntilExit()
        return output
    }

    // MARK: - Private

    private func waitUntilExit() throws {
        guard !didExit else { return }

        let data = fileHandle.readDataToEndOfFile()
        task.waitUntilExit()

        guard let result = String(data: data, encoding: encoding) else {
            throw PeripheryError.shellOuputEncodingFailed(cmd: cmd, args: args, encoding: encoding)
        }

        output += result
        didExit = true
    }
}

open class Shell: Singleton {
    public static func make() -> Self {
        return self.init()
    }

    private var tasks: Set<Process> = []
    private var tasksQueue = DispatchQueue(label: "Shell.tasksQueue")

    required public init() {}

    public func interruptRunning() {
        tasksQueue.sync { tasks.forEach { $0.interrupt() } }
    }

    private lazy var pristineEnvironment: [String: String] = {
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/bash"
        guard let pristineEnv = try? exec([shell, "-lc", "env"], stderr: false, environment: [:]) else {
            return ProcessInfo.processInfo.environment
        }

        return pristineEnv.trimmed
            .split(separator: "\n").map { line -> (String, String) in
                let pair = line.split(separator: "=", maxSplits: 1)
                return (String(pair.first ?? ""), String(pair.last ?? ""))
            }
            .reduce(into: [String: String]()) { (result, pair) in
                result[pair.0] = pair.1
            }
    }()

    @discardableResult
    open func exec(_ args: [String], stderr: Bool = true) throws -> String {
        let env = pristineEnvironment
        return try exec(args, stderr: stderr, environment: env)
    }

    // MARK: - Private

    private func exec(_ args: [String], stderr: Bool, environment: [String: String]) throws -> String {
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

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = stderr ? pipe : nil

        let logger: Logger = inject()
        logger.debug("[shell] \(launchPath) \(newArgs.joined(separator: " "))")

        tasksQueue.sync { _ = tasks.insert(task) }

        task.launch()

        let readable = ReadableStream(
            cmd: launchPath,
            args: newArgs,
            fileHandle: pipe.fileHandleForReading,
            task: task)

        let status = try readable.terminationStatus()
        let output = try readable.allOutput()

        tasksQueue.sync { _ = tasks.remove(task) }

        if status == 0 {
            return output
        }

        throw PeripheryError.shellCommandFailed(
            cmd: launchPath,
            args: newArgs,
            status: status,
            output: output)
    }
}
