import Foundation

class ExtensionAccessibilityCascader: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph,
                        featureManager: inject())
    }

    private let graph: SourceGraph
    private let featureManager: FeatureManager

    required init(graph: SourceGraph,
                  featureManager: FeatureManager) {
        self.graph = graph
        self.featureManager = featureManager
    }

    func visit() throws {
        if !featureManager.isEnabled(.determineAccessibilityFromStructure) {
            try cascadeUsingAttributeAccessibility()
        }
    }

    // MARK: - Private

    private func cascadeUsingAttributeAccessibility() throws {
        let extensionDeclarations = Declaration.Kind.extensionKinds.flatMap {
            graph.declarations(ofKind: $0)
        }
        let accessibilityNames = Accessibility.all.map { $0.shortName }

        for extensionDeclaration in extensionDeclarations {
            var extensionAccessibilityNames = extensionDeclaration.attributes.intersection(accessibilityNames)
            let extendedDeclaration = try graph.extendedDeclaration(forExtension: extensionDeclaration)

            if extendedDeclaration == nil && extensionAccessibilityNames.isEmpty {
                // SourceKit doesn't appear to currently provide the correct accessibility
                // attributes for extensions on external types, we'll therefore just consider them
                // all public
                extensionAccessibilityNames = [Accessibility.public.rawValue]
            }

            for declaration in extensionDeclaration.declarations {
                if declaration.attributes.isDisjoint(with: accessibilityNames) {
                    // The declaration does not explicitly specify an accessibility scope, it should
                    // therefore inherit the scope of the extension.
                    declaration.attributes.formUnion(extensionAccessibilityNames)
                }
            }
        }
    }
}
