import Foundation

final class DeclarationMarker: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() {
        mark(graph.retainedDeclarations)

        let rootReferencedDeclarations = Set(graph.rootReferences.flatMap { declarationsReferenced(by: $0) })
        mark(rootReferencedDeclarations)

        ignoreDereferencedDescendents(in: graph.rootDeclarations,
                                      dereferencedDeclarations: graph.dereferencedDeclarations)
    }

    // MARK: - Private

    private func mark(_ declarations: Set<Declaration>) {
        for declaration in declarations {
            guard !graph.markedDeclarations.contains(declaration) else { continue }

            graph.mark(declaration)
            mark(declarationsReferenced(by: declaration))
        }
    }

    private func declarationsReferenced(by declaration: Declaration) -> Set<Declaration> {
        let allReferences = declaration.references.union(declaration.related)
        return Set(allReferences.flatMap { declarationsReferenced(by: $0) })
    }

    private func declarationsReferenced(by reference: Reference) -> Set<Declaration> {
        var declarations: Set<Declaration> = []

        if let declaration = graph.explicitDeclaration(withUsr: reference.usr) {
            declarations.insert(declaration)
        }

        return declarations
    }

    private func ignoreDereferencedDescendents(in decls: Set<Declaration>, dereferencedDeclarations: Set<Declaration>) {
        for decl in decls {
            guard !decl.declarations.isEmpty || !decl.unusedParameters.isEmpty
                else { continue }

            if dereferencedDeclarations.contains(decl) {
                decl.descendentDeclarations.forEach { graph.markIgnored($0) }
                continue
            } else {
                ignoreDereferencedDescendents(in: decl.declarations,
                                              dereferencedDeclarations: dereferencedDeclarations)
            }
        }
    }
}
