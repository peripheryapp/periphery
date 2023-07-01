import Foundation

#if canImport(os)
import os
#endif

public enum ANSIColor: String {
    case bold = "\u{001B}[0;1m"
    case red = "\u{001B}[0;31m"
    case boldRed = "\u{001B}[0;1;31m"
    case green = "\u{001B}[0;32m"
    case boldGreen = "\u{001B}[0;1;32m"
    case yellow = "\u{001B}[0;33m"
    case boldYellow = "\u{001B}[0;1;33m"
    case blue = "\u{001B}[0;34m"
    case lightBlue = "\u{001B}[1;34m"
    case magenta = "\u{001B}[0;35m"
    case boldMagenta = "\u{001B}[0;1;35m"
    case cyan = "\u{001B}[0;36m"
    case white = "\u{001B}[0;37m"
    case gray = "\u{001B}[0;1;30m"
}

private var isColorOutputCapable: Bool = {
    guard let term = ProcessInfo.processInfo.environment["TERM"],
        term.lowercased() != "dumb",
        isatty(fileno(stdout)) != 0 else {
        return false
    }

    return true
}()

public func colorize(_ text: String, _ color: ANSIColor) -> String {
    guard isColorOutputCapable else { return text }
    return "\(color.rawValue)\(text)\u{001B}[0;0m"
}

public final class BaseLogger {
    public static let shared = BaseLogger()

    private let outputQueue: DispatchQueue

    private init() {
        self.outputQueue = DispatchQueue(label: "BaseLogger.outputQueue")
    }

    func info(_ text: String) {
        log(text, output: stdout)
    }

    func debug(_ text: String) {
        log(text, output: stdout)
    }

    func warn(_ text: String) {
        let text = colorize("warning: ", .boldYellow) + text
        log(text, output: stderr)
    }

    func error(_ text: String) {
        let text = colorize("error: ", .boldRed) + text
        log(text, output: stderr)
    }

    // MARK: - Private

    private func log(_ line: String, output: UnsafeMutablePointer<FILE>) {
        _ = outputQueue.sync { fputs(line + "\n", output) }
    }
}

public final class Logger {
    public static func configureBuffering() {
        var info = stat()
        fstat(STDOUT_FILENO, &info)

        if (info.st_mode & S_IFMT) == S_IFIFO {
            setlinebuf(stdout)
            setlinebuf(stderr)
        }
    }

    private let baseLogger: BaseLogger
    private let configuration: Configuration

    #if canImport(os)
    private let signposter = OSSignposter()
    #endif

    public required init(baseLogger: BaseLogger = .shared, configuration: Configuration = .shared) {
        self.baseLogger = baseLogger
        self.configuration = configuration
    }

    public func contextualized(with context: String) -> ContextualLogger {
        .init(logger: self, context: context)
    }

    public func info(_ text: String, canQuiet: Bool = true) {
        guard !(configuration.quiet && canQuiet) else { return }
        baseLogger.info(text)
    }

    public func debug(_ text: String) {
        if configuration.verbose {
            baseLogger.debug(text)
        }
    }

    public func warn(_ text: String) {
        baseLogger.warn(text)
    }

    public func error(_ text: String) {
        baseLogger.error(text)
    }

    public func beginInterval(_ name: StaticString) -> SignpostInterval {
        #if canImport(os)
        let id = signposter.makeSignpostID()
        let state = signposter.beginInterval(name, id: id)
        return .init(name: name, state: state)
        #else
        return SignpostInterval()
        #endif
    }

    public func endInterval(_ interval: SignpostInterval) {
        #if canImport(os)
        signposter.endInterval(interval.name, interval.state)
        #endif

    }
}

public struct ContextualLogger {
    let logger: Logger
    let context: String

    public func contextualized(with innerContext: String) -> ContextualLogger {
        logger.contextualized(with: "\(context):\(innerContext)")
    }

    public func debug(_ text: String) {
        logger.debug("[\(context)] \(text)")
    }

    public func warn(_ text: String) {
        logger.warn("[\(context)] \(text)")
    }

    public func beginInterval(_ name: StaticString) -> SignpostInterval {
        logger.beginInterval(name)
    }

    public func endInterval(_ interval: SignpostInterval) {
        logger.endInterval(interval)
    }
}

#if canImport(os)
public struct SignpostInterval {
    let name: StaticString
    let state: OSSignpostIntervalState
}
#else
public struct SignpostInterval {}
#endif
