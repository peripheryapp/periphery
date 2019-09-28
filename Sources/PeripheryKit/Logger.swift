import Foundation

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

public func colorize(_ text: String, _ color: ANSIColor) -> String {
    guard let term = ProcessInfo.processInfo.environment["TERM"],
        term.lowercased() != "dumb",
        isatty(fileno(stdout)) != 0 else {
        return text
    }

    return "\(color.rawValue)\(text)\u{001B}[0;0m"
}

public final class Logger: Singleton {
    public static func make() -> Self {
        return self.init(configuration: inject())
    }

    private let configuration: Configuration
    private let outputQueue: DispatchQueue

    required public init(configuration: Configuration) {
        self.configuration = configuration
        self.outputQueue = DispatchQueue(label: "Logger.outputQueue")
    }

    public func info(_ text: String, canQuiet: Bool = true) {
        guard !(configuration.quiet && canQuiet) else { return }
        log(text, output: stdout)
    }

    public func debug(_ text: String) {
        if configuration.verbose {
            log(text, output: stdout)
        }
    }

    public func warn(_ text: String) {
        let text = colorize("warning: ", .boldYellow) + text
        log(text, output: stderr)
    }

    public func important(_ text: String) {
        let text = colorize("important: ", .boldYellow) + text
        log(text, output: stdout)
    }

    public func hint(_ text: String) {
        let text = colorize("hint: ", .boldMagenta) + colorize(text, .bold)
        log(text, output: stdout)
    }

    public func error(_ text: String) {
        let text = colorize("error: ", .boldRed) + colorize(text, .bold)
        log(text, output: stderr)
    }

    public func error(_ e: Error) {
        error(e.localizedDescription)
    }

    // MARK: - Private

    private func log(_ line: String, output: UnsafeMutablePointer<FILE>) {
        _ = outputQueue.sync { fputs(line + "\n", output) }
    }
}
