import Foundation

/// https://bugs.swift.org/browse/SR-7093
/// Due to a SourceKit bug, constructors on a class with generic type parameters are not referenced
/// despite being used. We therefore must reference the constrcutor from the class.
final class GenericClassConstructorReferenceBuilder: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() {
        let genericClassDeclarations = graph.declarations(ofKind: .class).filter {
            $0.declarations.contains { $0.kind == .genericTypeParam }
        }

        for declaration in genericClassDeclarations {
            let constructors = declaration.declarations.filter { $0.kind == .functionConstructor }

            for constructor in constructors {
                let reference = Reference(kind: .functionConstructor,
                                          usr: constructor.usr,
                                          location: declaration.location)
                reference.parent = declaration
                graph.add(reference, from: declaration)
            }
        }
    }
}
