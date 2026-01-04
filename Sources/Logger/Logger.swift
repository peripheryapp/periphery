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
    case lightGray = "\u{001B}[0;37m"
    case gray = "\u{001B}[0;1;30m"
}

public struct Logger: Sendable {
    let outputQueue: DispatchQueue
    let quiet: Bool
    let verbose: Bool
    let coloredOutputEnabled: Bool

    #if canImport(os)
        let signposter = OSSignposter()
    #endif

    private var isColorOutputCapable: Bool = {
        guard let term = ProcessInfo.processInfo.environment["TERM"],
              term.lowercased() != "dumb",
              isatty(fileno(stdout)) != 0
        else {
            return false
        }

        return true
    }()

    public init(
        quiet: Bool,
        verbose: Bool,
        coloredOutputEnabled: Bool
    ) {
        self.quiet = quiet
        self.verbose = verbose
        self.coloredOutputEnabled = coloredOutputEnabled
        outputQueue = DispatchQueue(label: "Logger.outputQueue")
    }

    public func colorize(_ text: String, _ color: ANSIColor) -> String {
        guard isColorOutputCapable, coloredOutputEnabled else { return text }
        return "\(color.rawValue)\(text)\u{001B}[0;0m"
    }

    public func contextualized(with context: String) -> ContextualLogger {
        .init(logger: self, context: context)
    }

    public func info(_ text: String, canQuiet: Bool = true) {
        guard !(quiet && canQuiet) else { return }
        log(text, output: stdout)
    }

    public func debug(_ text: String) {
        guard verbose else { return }
        log(text, output: stdout)
    }

    public func warn(_ text: String, newlinePrefix: Bool = false) {
        guard !quiet else { return }
        if newlinePrefix {
            log("", output: stderr)
        }
        let text = colorize("warning: ", .boldYellow) + text
        log(text, output: stderr)
    }

    // periphery:ignore
    public func error(_ text: String) {
        let text = colorize("error: ", .boldRed) + text
        log(text, output: stderr)
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

    // MARK: - Private

    func log(_ line: String, output: UnsafeMutablePointer<FILE>) {
        _ = outputQueue.sync { fputs(line + "\n", output) }
    }
}

public struct ContextualLogger: Sendable {
    let logger: Logger
    let context: String

    public func contextualized(with innerContext: String) -> ContextualLogger {
        logger.contextualized(with: "\(context):\(innerContext)")
    }

    public func debug(_ text: String) {
        logger.debug("[\(context)] \(text)")
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
    public struct SignpostInterval {
        @usableFromInline
        init() {}
    }
#endif
