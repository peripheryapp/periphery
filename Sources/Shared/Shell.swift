import Foundation

final class ReadableStream {
    private let args: [String]
    private let fileHandle: FileHandle
    private let task: Process
    private let encoding: String.Encoding
    private var output = ""
    private var didExit = false

    init(args: [String], fileHandle: FileHandle, task: Process, encoding: String.Encoding = .utf8) {
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
            throw PeripheryError.shellOuputEncodingFailed(args: args, encoding: encoding)
        }

        output += result
        didExit = true
    }
}

open class Shell: Injectable {
    public static func make() -> Self {
        return self.init()
    }

    private static var tasks: Set<Process> = []
    private static var tasksQueue = DispatchQueue(label: "Shell.tasksQueue")

    required public init() {}

    public static func terminateAll() {
        tasksQueue.sync { tasks.forEach { $0.terminate() } }
    }

    @discardableResult
    open func exec(_ args: [String], stderr: Bool = true, env: [String: String] = ProcessInfo.processInfo.environment) throws -> String {
        let task = Process()
        task.environment = env
        task.launchPath = "/usr/bin/env"
        task.arguments = args

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = stderr ? pipe : nil

        let logger: Logger = inject()
        logger.debug("[shell] \(args.joined(separator: " "))")

        Shell.tasksQueue.sync { _ = Shell.tasks.insert(task) }

        task.launch()

        let readable = ReadableStream(args: args,
                                      fileHandle: pipe.fileHandleForReading,
                                      task: task)

        let status = try readable.terminationStatus()
        let output = try readable.allOutput()

        Shell.tasksQueue.sync { _ = Shell.tasks.remove(task) }

        if status == 0 {
            return output
        }

        throw PeripheryError.shellCommandFailed(args: args,
                                                   status: status,
                                                   output: output)
    }
}
