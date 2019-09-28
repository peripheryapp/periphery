import Foundation

/// Builds references to enum cases of enums that are raw representable.
/// Disabled in aggressive mode.
final class EnumCaseReferenceBuilder: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph, configuration: inject())
    }

    private let graph: SourceGraph
    private let configuration: Configuration

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
        self.configuration = configuration
    }

    func visit() {
        for enumDeclaration in graph.declarations(ofKind: .enum) {
            if isRawRepresentable(enumDeclaration) {
                let enumCases = enumDeclaration.declarations.filter { $0.kind == .enumelement }

                if configuration.aggressive {
                    enumCases.forEach { $0.analyzerHints.append(.aggressive) }
                } else {
                    for enumCase in enumCases {
                        let reference = Reference(kind: .enumelement, usr: enumCase.usr, location: enumCase.location)
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

        return graph.superclassReferences(of: enumDeclaration).contains {
            $0.kind == .protocol && $0.name == "RawRepresentable"
        }
    }
}
