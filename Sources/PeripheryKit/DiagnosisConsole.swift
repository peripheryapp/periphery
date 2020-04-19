import Foundation

public final class DiagnosisConsole {
    private let graph: SourceGraph

    public init(graph: SourceGraph) {
        self.graph = graph
    }

    public func start() {
        print(colorize("\nWelcome to the diagnosis console.", .bold))
        print("Type 'help' for instructions, ^C to exit.")

        while true {
            print(colorize("> ", .boldGreen), separator: "", terminator: "")

            if let command = readLine(strippingNewline: true) {
                process(command)
            } else {
                break
            }
        }
    }

    // MARK: - Private

    private func process(_ command: String) {
        let parts = command.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)

        guard let action = parts.first else { return }
        let args = parts.suffix(from: 1).map { String($0) }

        if action == "help" {
            help()
        } else if ["s", "search"].contains(action) {
            search(args)
        } else if ["i", "inspect"].contains(action) {
            inspect(args)
        } else if ["exit", "quit"].contains(action) {
            exit(0)
        } else {
            print("No such command '\(action)', type 'help' for instructions.")
        }
    }

    private func help() {
        print(
            "Available commands:\n\n" +
                "(s)earch <term> - Show all declarations with a name containing <term>.\n" +
            "(i)nspect <id> - Describe active ancestral declarations that reference the declaration identified by <id>."
        )
    }

    private func search(_ args: [String]) {
        guard let term = args.first?.trimmed, term != "" else {
            print("Search requires a term, see 'help' for details.")
            return
        }

        let matches = graph.allDeclarations.filter {
            let name = $0.name ?? ""
            return name.contains(term)
        }

        if matches.count > 0 {
            print("Found \("declaration".counted(matches.count)) containing '\(term)':\n")
            matches.forEach { print(format($0)) }
        } else {
            print("No declarations found containing '\(term)'.")
        }
    }

    private func inspect(_ args: [String]) {
        guard var usr = args.first?.trimmed, usr != "" else {
            print("Inspect requires a declaration ID, see 'help' for details.")
            return
        }

        if usr.hasPrefix("'") {
            usr = String(usr.dropFirst())
        }

        if usr.hasSuffix("'") {
            usr = String(usr.dropLast())
        }

        guard let declaration = graph.explicitDeclaration(withUsr: usr) else {
            print("No declaration found with ID '\(usr)'")
            return
        }

        guard graph.isReferenced(declaration) else {
            let preamble = "Declaration '\(declaration.name ?? "N/A")' does not have any active references"

            if declaration.retentionReason == .unknown {
                print("\(preamble); it appears to be unused.")
            } else {
                let reason = retentionReasonDescription(declaration.retentionReason)
                print("\(preamble), though it is retained because: \(reason)")
            }

            return
        }

        print(colorize("\nDeclaration hierarchy:\n", .bold))
        print(format(declaration))
        var depth = 1

        for ancestor in declaration.ancestralDeclarations {
            let indent = String(repeating: "··", count: depth)
            print(indent + " " + format(ancestor))
            depth += 1
        }

        print(colorize("\nActive references:\n", .bold))

        let references = graph.activeReferences(to: declaration)
        references.forEach { print(format($0)) }
    }

    private func retentionReasonDescription(_ reason: Declaration.RetentionReason) -> String {
        switch reason {
        case .rootEquatableInfixOperator:
            return "declaraton is a global Equatable infix operator."
        case .xctest:
            return "declaration is an XCTest test case or test method."
        case .mainEntryPoint:
            return "declaration is declared in main.swift."
        case .unknownTypeConformance:
            return "declaration conforms to an externally declared protocol."
        case .xib:
            return "declaration is referenced by an Xib or Storyboard."
        case .unknown:
            return "unknown."
        case .applicationMain:
            return "declaration is annotated with @NS/UIApplicationMain."
        case .publicAccessible:
            return "declaration is 'public' and the '--retain-public' option is in effect. Disable this behavior with '--no-retain-public'."
        case .objcAnnotated:
            return "declaration is accessible by Objective-C and the '--retain-objc-annotated' option is in effect. Disable this behavior with '--no-retain-objc-annotated'."
        case .unknownTypeExtension:
            return "declaration extends an externally declared type."
        case .paramFuncOverridden:
            return "parameter is used in another overridden function with the same signature."
        case .paramFuncForeginProtocol:
            return "parameter is member of function that conforms to foreign protocol."
        case .paramFuncLocalProtocol:
            return "parameter is used in another protocol conforming function with the same signature."
        }
    }

    func format(_ declaration: Declaration) -> String {
        return "[\(declaration.descriptionParts.joined(separator: ", "))]"
    }

    func format(_ reference: Reference) -> String {
        return reference.location.description
    }
}
