import Foundation

// Retains all properties that are named by an implicit constructor.
// In the case of a Codable conforming struct (and possibly others), properties are used even if they have no other
// references than from the implicit constructor.
final class StructImplicitConstructorPropertyRetainer: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() {
        for structDecl in graph.declarations(ofKind: .struct) {
            let implicitConstructors = structDecl.declarations.filter { $0.isImplicit && $0.kind == .functionConstructor }

            for constructor in implicitConstructors {
                let varNames = argumentNames(in: constructor.name)

                structDecl.declarations
                    .filter { $0.kind == .varInstance && varNames.contains($0.name ?? "") }
                    .forEach { graph.markRetained($0) }
            }
        }
    }

    // MARK: - Private

    private func argumentNames(in signature: String?) -> [String] {
        signature?
            .split(separator: "(").last?
            .split(separator: ")").first?
            .split(separator: ":")
            .map { String($0) } ?? []
    }
}
