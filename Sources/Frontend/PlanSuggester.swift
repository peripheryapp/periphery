import Foundation
import Logger

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

enum LocLimit {
    case unlimited
    case limited(Int)

    init(rawValue: Int) {
        self = rawValue <= 0 ? .unlimited : .limited(rawValue)
    }

    var displayString: String {
        switch self {
        case .unlimited:
            return "unlimited LOC"
        case let .limited(n):
            let formatted = if n >= 1_000_000 {
                "\(n / 1_000_000)M"
            } else if n >= 1000 {
                "\(n / 1000)k"
            } else {
                "\(n)"
            }
            return "up to \(formatted) LOC"
        }
    }
}

struct SuggestedPlan {
    let name: String
    let locLimit: LocLimit
    let free: Bool
}

final class PlanSuggester {
    private let logger: Logger
    private let loc: Int
    private let urlSession: URLSession
    private var suggestedPlan: SuggestedPlan?
    private let semaphore: DispatchSemaphore

    private static let apiBaseURL: URL = {
        if let override = ProcessInfo.processInfo.environment["PERIPHERY_API_BASE_URL"],
           let url = URL(string: override)
        {
            return url
        }
        return URL(string: "https://api.periphery.pro/v1")!
    }()

    init(
        logger: Logger,
        loc: Int
    ) {
        self.logger = logger
        self.loc = loc
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        urlSession = URLSession(configuration: config)
        semaphore = DispatchSemaphore(value: 0)
    }

    deinit {
        urlSession.invalidateAndCancel()
    }

    func run() {
        guard loc > 0 else {
            semaphore.signal()
            return
        }

        var components = URLComponents(url: Self.apiBaseURL.appendingPathComponent("suggest-plan"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "loc", value: String(loc))]

        guard let url = components.url else {
            semaphore.signal()
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let task = urlSession.dataTask(with: request) { [weak self] data, _, error in
            guard let self else { return }
            guard error == nil,
                  let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                semaphore.signal()
                return
            }

            if let planObj = json["suggested_plan"] as? [String: Any],
               let name = planObj["name"] as? String,
               let locLimitRaw = planObj["loc_limit"] as? Int
            {
                let free = planObj["free"] as? Bool ?? false
                suggestedPlan = SuggestedPlan(name: name, locLimit: LocLimit(rawValue: locLimitRaw), free: free)
            }

            semaphore.signal()
        }

        task.resume()
    }

    func notifyIfSuggested() {
        _ = semaphore.wait(timeout: .now() + 1)

        guard let plan = suggestedPlan else { return }

        let boldPlan = logger.colorize(plan.name, .bold)
        let formattedLoc = loc.formatted(.number.grouping(.automatic))
        let freeNote = plan.free ? " — free!" : ""
        let suggestion = "Based on your project size (\(formattedLoc) LOC), the \(boldPlan) plan (\(plan.locLimit.displayString)\(freeNote)) would be a great fit."

        let lines = [
            logger.colorize("Periphery is moving to a usage-based model.", .boldGreen),
            "",
            "Open-source and small projects will continue to use Periphery for free but larger projects will require a paid plan. \(suggestion)",
            "",
            "Learn more at " + logger.colorize("https://periphery.pro", .bold),
        ]

        let contentWidth = 70
        let wrapped = lines.flatMap { wordWrap($0, maxWidth: contentWidth) }
        let horizontal = String(repeating: "─", count: contentWidth + 2)
        var box = "\n┌\(horizontal)┐"
        for line in wrapped {
            let padding = String(repeating: " ", count: contentWidth - visibleLength(line))
            box += "\n│ \(line)\(padding) │"
        }
        box += "\n└\(horizontal)┘"

        logger.info(box)
    }

    private func wordWrap(_ text: String, maxWidth: Int) -> [String] {
        guard visibleLength(text) > maxWidth else { return [text] }

        let reset = "\u{001B}[0;0m"

        // Split into words, keeping ANSI codes attached to adjacent text.
        var words: [String] = []
        var current = ""
        var inEscape = false

        for char in text {
            if inEscape {
                current.append(char)
                if char == "m" { inEscape = false }
            } else if char == "\u{001B}" {
                current.append(char)
                inEscape = true
            } else if char == " " {
                if !current.isEmpty {
                    words.append(current)
                    current = ""
                }
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty { words.append(current) }

        // Build lines by adding words until width exceeds max.
        var lines: [String] = []
        var currentLine = ""
        var currentWidth = 0

        for word in words {
            let wordWidth = visibleLength(word)
            if currentWidth == 0 {
                currentLine = word
                currentWidth = wordWidth
            } else if currentWidth + 1 + wordWidth <= maxWidth {
                currentLine += " " + word
                currentWidth += 1 + wordWidth
            } else {
                lines.append(currentLine)
                currentLine = word
                currentWidth = wordWidth
            }
        }
        if !currentLine.isEmpty { lines.append(currentLine) }

        // Re-open/close ANSI styles across line breaks.
        var result: [String] = []
        var activeStyle: String?

        for line in lines {
            var outputLine = line
            if let style = activeStyle {
                outputLine = style + outputLine
            }

            // Scan the original line content to track which style is active at its end.
            var escBuf = ""
            var scanning = false
            for char in line {
                if scanning {
                    escBuf.append(char)
                    if char == "m" {
                        scanning = false
                        activeStyle = escBuf == reset ? nil : escBuf
                        escBuf = ""
                    }
                } else if char == "\u{001B}" {
                    scanning = true
                    escBuf = "\u{001B}"
                }
            }

            if activeStyle != nil {
                outputLine += reset
            }

            result.append(outputLine)
        }

        return result
    }

    private func visibleLength(_ text: String) -> Int {
        text.replacingOccurrences(
            of: "\u{001B}\\[[0-9;]*m",
            with: "",
            options: .regularExpression
        ).count
    }
}
