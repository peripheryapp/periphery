import Foundation

class InterfaceBuilderPropertyRetainer {
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
                if decl.attributes.contains(where: { ibInspectableAttributes.contains($0) }) {
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
        referencedAttributes: Set<String>,
    ) {
        let inheritedDeclarations = graph.inheritedDeclarations(of: declaration)
        let descendentInheritedDeclarations = inheritedDeclarations.map(\.declarations).joined()
        let allDeclarations = declaration.declarations.union(descendentInheritedDeclarations)

        for decl in allDeclarations {
            guard let declName = decl.name else { continue }

            // Check IBOutlet properties
            if decl.attributes.contains(where: { ibOutletAttributes.contains($0) }) {
                if referencedOutlets.contains(declName) {
                    graph.markRetained(decl)
                }
                continue
            }

            // Check IBAction/IBSegueAction methods
            if decl.attributes.contains(where: { ibActionAttributes.contains($0) }) {
                let selectorName = swiftNameToSelector(declName)
                if referencedActions.contains(selectorName) {
                    graph.markRetained(decl)
                }
                continue
            }

            // Check IBInspectable properties
            if decl.attributes.contains(where: { ibInspectableAttributes.contains($0) }) {
                if referencedAttributes.contains(declName) {
                    graph.markRetained(decl)
                }
                continue
            }
        }
    }

    // MARK: - Private

    /// Converts a Swift function name like `click(_:)` or `doSomething(_:withValue:)`
    /// to an Objective-C selector like `click:` or `doSomething:withValue:`.
    private func swiftNameToSelector(_ swiftName: String) -> String {
        // Remove the trailing parenthesis content to get just the method name with params
        // e.g., "click(_:)" -> "click:" or "handleTap(_:forEvent:)" -> "handleTap:forEvent:"
        guard let parenStart = swiftName.firstIndex(of: "("),
              let parenEnd = swiftName.lastIndex(of: ")")
        else {
            return swiftName
        }

        let methodName = String(swiftName[..<parenStart])
        let paramsSection = String(swiftName[swiftName.index(after: parenStart) ..< parenEnd])

        // Split by ":" to get parameter labels
        let params = paramsSection.split(separator: ":", omittingEmptySubsequences: false)

        // Build the selector: methodName + ":" for each parameter
        var selector = methodName
        for (index, param) in params.enumerated() {
            if index == 0 {
                // First parameter: just add ":"
                selector += ":"
            } else if !param.isEmpty {
                // Subsequent parameters: add label + ":"
                selector += String(param) + ":"
            }
        }

        return selector
    }
}
