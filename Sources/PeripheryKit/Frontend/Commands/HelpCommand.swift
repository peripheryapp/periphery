import Foundation
import Commandant
import Result

public struct HelpCommand<ClientError: Error>: CommandProtocol {
    public typealias Options = HelpOptions<ClientError>

    public let verb = "help"
    public let function = "Display general or command-specific help"

    private let registry: CommandRegistry<ClientError>

    /// Initializes the command to provide help from the given registry of
    /// commands.
    public init(registry: CommandRegistry<ClientError>) {
        self.registry = registry
    }

    public func run(_ options: Options) -> Result<(), ClientError> {
        if let verb = options.verb {
            if let command = self.registry[verb] {
                print(command.function)
                if let usageError = command.usage() {
                    print("\n\(usageError)")
                }
                return .success(())
            } else {
                fputs("Unrecognized command: '\(verb)'\n", stderr)
            }
        }

        print("USAGE:\n")

        print("   periphery <command> [options]\n")
        print("   To view availale options for a given command: periphery help <command>\n")

        print("COMMANDS:\n")

        let maxVerbLength = self.registry.commands.map { $0.verb.count }.max() ?? 0

        for command in self.registry.commands {
            let padding = repeatElement(Character(" "), count: maxVerbLength - command.verb.count)
            print("   \(command.verb)\(String(padding))   \(command.function)")
        }

        return .success(())
    }
}

public struct HelpOptions<ClientError: Error>: OptionsProtocol {
    fileprivate let verb: String?

    private init(verb: String?) {
        self.verb = verb
    }

    private static func create(_ verb: String) -> HelpOptions {
        return self.init(verb: (verb == "" ? nil : verb))
    }

    public static func evaluate(_ m: CommandMode) -> Result<HelpOptions, CommandantError<ClientError>> {
        return create
            <*> m <| Argument(defaultValue: "", usage: "the command to display help for")
    }
}
