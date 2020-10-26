import Foundation

protocol SetupGuide {
    func perform() throws
    var commandLineOptions: [String] { get }
}

class SetupGuideHelpers {
    func display(options: [String]) {
        let maxPaddingCount = String(options.count).count

        for (index, option) in options.enumerated() {
            let paddingCount = maxPaddingCount - String(index + 1).count
            let pading = String(repeating: " ", count: paddingCount)
            print(pading + colorize("\(index + 1) ", .boldGreen) + option)
        }
    }

    func select(single options: [String]) -> String {
        display(options: options)
        print(colorize("> ", .bold), terminator: "")

        if let strChoice = readLine(strippingNewline: true)?.trimmed,
           let choice = Int(strChoice) {
            if let option = options[safe: choice - 1] {
                return option
            } else {
                print(colorize("\nInvalid option: \(strChoice)\n", .boldYellow))
            }
        }

        print(colorize("\nInvalid input, expected a number.\n", .boldYellow))
        return select(single: options)
    }

    func select(multiple options: [String], allowAll: Bool) -> [String] {
        var helpMsg = " Delimit choices with a single space, e.g: 1 2 3"

        if allowAll {
            helpMsg += ", or 'all' to select all options"
        }

        print(colorize("?", .boldYellow) + helpMsg)
        display(options: options)
        print(colorize("> ", .bold), terminator: "")
        var selected: [String] = []

        if let strChoices = readLine(strippingNewline: true)?.trimmed.split(separator: " ", omittingEmptySubsequences: true) {
            if allowAll && strChoices.contains("all") {
                selected = options
            } else {
                for strChoice in strChoices {
                    if let choice = Int(strChoice),
                       let option = options[safe: choice - 1] {
                        selected.append(option)
                    } else {
                        print(colorize("\nInvalid option: \(strChoice)\n", .boldYellow))
                        return select(multiple: options, allowAll: allowAll)
                    }
                }
            }
        }

        if !selected.isEmpty { return selected }

        print(colorize("\nInvalid input, expected a number.\n", .boldYellow))
        return select(multiple: options, allowAll: allowAll)
    }

    func selectBoolean() -> Bool {
        print(
            "(" + colorize("Y", .boldGreen) + ")es" +
                "/" +
                "(" + colorize("N", .boldGreen) + ")o" +
                colorize(" > ", .bold),
            terminator: ""
        )

        if let answer = readLine(strippingNewline: true)?.trimmed.lowercased(),
           !answer.isEmpty {
            if ["y", "yes"].contains(answer) {
                return true
            } else if ["n", "no"].contains(answer) {
                return false
            }
        }

        print(colorize("\nInvalid input, expected 'y' or 'n'.\n", .boldYellow))
        return selectBoolean()
    }
}
