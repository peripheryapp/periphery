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

@usableFromInline var isColorOutputCapable: Bool = {
    guard let term = ProcessInfo.processInfo.environment["TERM"],
          term.lowercased() != "dumb",
          isatty(fileno(stdout)) != 0
    else {
        return false
    }

    return true
}()

@inlinable
public func colorize(_ text: String, _ color: ANSIColor) -> String {
    guard isColorOutputCapable else { return text }
    return "\(color.rawValue)\(text)\u{001B}[0;0m"
}

public final class BaseLogger {
    public static let shared = BaseLogger()

    @usableFromInline let outputQueue: DispatchQueue

    private init() {
        outputQueue = DispatchQueue(label: "BaseLogger.outputQueue")
    }

    @inlinable
    public func info(_ text: String) {
        log(text, output: stdout)
    }

    @inlinable
    public func debug(_ text: String) {
        log(text, output: stdout)
    }

    @inlinable
    public func warn(_ text: String, newlinePrefix: Bool = false) {
        if newlinePrefix {
            log("", output: stderr)
        }
        let text = colorize("warning: ", .boldYellow) + text
        log(text, output: stderr)
    }

    @inlinable
    public func error(_ text: String) {
        let text = colorize("error: ", .boldRed) + text
        log(text, output: stderr)
    }

    // MARK: - Private

    @inlinable
    func log(_ line: String, output: UnsafeMutablePointer<FILE>) {
        _ = outputQueue.sync { fputs(line + "\n", output) }
    }
}
