import Foundation

/// Builds references to enum cases of enums that are raw representable.
final class EnumCaseReferenceBuilder: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() {
        for enumDeclaration in graph.declarations(ofKind: .enum) {
            if isRawRepresentable(enumDeclaration) {
                let enumCases = enumDeclaration.declarations.filter { $0.kind == .enumelement }

                for enumCase in enumCases {
                    for usr in enumCase.usrs {
                        let reference = Reference(kind: .enumelement, usr: usr, location: enumCase.location)
                        reference.name = enumCase.name
                        reference.parent = enumDeclaration
                        graph.add(reference, from: enumDeclaration)
                    }
                }
            }
        }
    }

    // MARK: - Private

    func isRawRepresentable(_ enumDeclaration: Declaration) -> Bool {
        // If the enum has a related struct it's very likely to be raw representable,
        // and thus is dynamic in nature.

        if enumDeclaration.related.contains(where: { $0.kind == .struct }) {
            return true
        }

        return graph.inheritedTypeReferences(of: enumDeclaration).contains {
            $0.kind == .protocol && $0.name == "RawRepresentable"
        }
    }
}
