import Foundation
import Logger

public protocol SetupGuide {
    func perform() throws -> ProjectKind
    var commandLineOptions: [String] { get }
    var projectKindName: String { get }
}

public enum SetupSelection {
    case all([String])
    case some([String])

    public var selectedValues: [String] {
        switch self {
        case let .all(values), let .some(values):
            values
        }
    }
}

open class SetupGuideHelpers {
    public init() {}

    func display(options: [String]) {
        let maxPaddingCount = String(options.count).count

        for (index, option) in options.enumerated() {
            let paddingCount = maxPaddingCount - String(index + 1).count
            let padding = String(repeating: " ", count: paddingCount)
            print(padding + Logger.colorize("\(index + 1) ", .boldGreen) + option)
        }
    }

    public func select(single options: [String]) -> String {
        display(options: options)
        print(Logger.colorize("?", .boldYellow) + " Type the number for the option you wish to select")
        print(Logger.colorize("=> ", .bold), terminator: "")

        if let strChoice = readLine(strippingNewline: true)?.trimmed,
           let choice = Int(strChoice)
        {
            if let option = options[safe: choice - 1] {
                return option
            } else {
                print(Logger.colorize("\nInvalid option: \(strChoice)\n", .boldYellow))
            }
        }

        print(Logger.colorize("\nInvalid input, expected a number.\n", .boldYellow))
        return select(single: options)
    }

    public func select(multiple options: [String]) -> SetupSelection {
        let helpMsg = " Delimit choices with a single space, e.g: 1 2 3"

        display(options: options)
        print(Logger.colorize("?", .boldYellow) + helpMsg)
        print(Logger.colorize("=> ", .bold), terminator: "")

        if let strChoices = readLine(strippingNewline: true)?.trimmed.split(separator: " ", omittingEmptySubsequences: true) {
            var selected: [String] = []

            for strChoice in strChoices {
                if let choice = Int(strChoice),
                   let option = options[safe: choice - 1]
                {
                    selected.append(option)
                } else {
                    print(Logger.colorize("\nInvalid option: \(strChoice)\n", .boldYellow))
                    return select(multiple: options)
                }
            }

            if !selected.isEmpty { return .some(selected) }
        }

        print(Logger.colorize("\nInvalid input, expected a number.\n", .boldYellow))
        return select(multiple: options)
    }

    public func selectBoolean() -> Bool {
        print(
            "(" + Logger.colorize("Y", .boldGreen) + ")es" +
                "/" +
                "(" + Logger.colorize("N", .boldGreen) + ")o" +
                Logger.colorize("\n=> ", .bold),
            terminator: "",
        )

        if let answer = readLine(strippingNewline: true)?.trimmed.lowercased(),
           !answer.isEmpty
        {
            if ["y", "yes"].contains(answer) {
                return true
            } else if ["n", "no"].contains(answer) {
                return false
            }
        }

        print(Logger.colorize("\nInvalid input, expected 'y' or 'n'.\n", .boldYellow))
        return selectBoolean()
    }
}
