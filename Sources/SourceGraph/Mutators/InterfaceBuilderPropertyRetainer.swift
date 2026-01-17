import Foundation

final class InterfaceBuilderPropertyRetainer {
    private let graph: SourceGraph
    private let ibOutletAttributes: Set<String> = ["IBOutlet"]
    private let ibActionAttributes: Set<String> = ["IBAction", "IBSegueAction"]
    private let ibInspectableAttributes: Set<String> = ["IBInspectable"]

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    /// Retains IBInspectable properties declared in extensions on external types.
    /// These cannot be reliably matched to XIB runtime attributes since the extended
    /// type may not have a customClass in the XIB.
    func retainPropertiesDeclaredInExtensions(referencedAttributes: Set<String>) {
        let extensions = graph.declarations(ofKind: .extensionClass)

        for extDecl in extensions {
            for decl in extDecl.declarations {
                // IBInspectable properties in extensions: check if referenced
                if decl.attributes.contains(where: { ibInspectableAttributes.contains($0.name) }) {
                    if let name = decl.name, referencedAttributes.contains(name) {
                        graph.markRetained(decl)
                    }
                }
            }
        }
    }

    /// Retains only the outlets, actions, and inspectable properties that are actually
    /// referenced in the Interface Builder file.
    func retainPropertiesDeclared(
        in declaration: Declaration,
        referencedOutlets: Set<String>,
        referencedActions: Set<String>,
        referencedAttributes: Set<String>
    ) {
        let inheritedDeclarations = graph.inheritedDeclarations(of: declaration)
        let descendentInheritedDeclarations = inheritedDeclarations.map(\.declarations).joined()
        let allDeclarations = declaration.declarations.union(descendentInheritedDeclarations)

        for decl in allDeclarations {
            guard let declName = decl.name else { continue }

            // Check IBOutlet properties
            if decl.attributes.contains(where: { ibOutletAttributes.contains($0.name) }) {
                if referencedOutlets.contains(declName) {
                    graph.markRetained(decl)
                }
                continue
            }

            // Check IBAction/IBSegueAction methods
            if decl.attributes.contains(where: { ibActionAttributes.contains($0.name) }) {
                let selectorName = Self.swiftNameToSelector(declName)
                if referencedActions.contains(selectorName) {
                    graph.markRetained(decl)
                }
                continue
            }

            // Check IBInspectable properties
            if decl.attributes.contains(where: { ibInspectableAttributes.contains($0.name) }) {
                if referencedAttributes.contains(declName) {
                    graph.markRetained(decl)
                }
                continue
            }
        }
    }

    // MARK: - Helpers

    /// Prepositions that Swift recognizes for Objective-C selector conversion.
    /// When a first parameter label is one of these, it's just capitalized without adding "With".
    /// Source: https://github.com/apple/swift/blob/main/lib/Basic/PartsOfSpeech.def
    private static let knownPrepositions: Set<String> = [
        "above", "after", "along", "alongside", "as", "at",
        "before", "below", "by",
        "following", "for", "from",
        "given",
        "in", "including", "inside", "into",
        "matching",
        "of", "on",
        "passing", "preceding",
        "since",
        "to",
        "until", "using",
        "via",
        "when", "with", "within",
    ]

    /// Converts a Swift function name like `click(_:)` or `doSomething(_:withValue:)`
    /// to an Objective-C selector like `click:` or `doSomething:withValue:`.
    ///
    /// Swift to Objective-C selector conversion rules:
    /// - `func myMethod()` → `myMethod` (no parameters, no colon)
    /// - `func myMethod(_ sender: Any)` → `myMethod:` (unnamed first param)
    /// - `func myMethod(sender: Any)` → `myMethodWithSender:` (named first param gets "With" prefix)
    /// - `func myMethod(for value: Any)` → `myMethodFor:` (preposition labels are just capitalized)
    /// - `func myMethod(_:secondParam:)` → `myMethod:secondParam:`
    /// - `func myMethod(firstParam:secondParam:)` → `myMethodWithFirstParam:secondParam:`
    static func swiftNameToSelector(_ swiftName: String) -> String {
        guard let parenStart = swiftName.firstIndex(of: "("),
              let parenEnd = swiftName.lastIndex(of: ")")
        else {
            return swiftName
        }

        let methodName = String(swiftName[..<parenStart])
        let paramsSection = String(swiftName[swiftName.index(after: parenStart) ..< parenEnd])

        // No parameters: return just the method name (no colon)
        if paramsSection.isEmpty {
            return methodName
        }

        // Split by ":" to get parameter labels
        let params = paramsSection.split(separator: ":", omittingEmptySubsequences: false)

        // Build the selector
        var selector = methodName
        for (index, param) in params.enumerated() {
            if index == 0 {
                // First parameter handling
                if param == "_" || param.isEmpty {
                    // Unnamed first param: just add ":"
                    selector += ":"
                } else {
                    let label = String(param)
                    let lowercasedLabel = label.lowercased()

                    // Check if label is a known preposition or starts with "with"
                    if knownPrepositions.contains(lowercasedLabel) || lowercasedLabel.hasPrefix("with") {
                        // Prepositions and "with*" labels are just capitalized
                        // e.g., "for" -> "For:", "with" -> "With:", "withSender" -> "WithSender:"
                        selector += label.prefix(1).uppercased() + label.dropFirst() + ":"
                    } else {
                        // Other labels get "With" prefix
                        // e.g., "sender" -> "WithSender:"
                        selector += "With" + label.prefix(1).uppercased() + label.dropFirst() + ":"
                    }
                }
            } else if !param.isEmpty {
                // Subsequent parameters: add label + ":"
                selector += String(param) + ":"
            }
        }

        return selector
    }
}
