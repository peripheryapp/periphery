import Foundation

/// https://bugs.swift.org/browse/SR-7093
/// Constructors on a class/struct with generic type parameters are not referenced despite being used.
/// We therefore must reference the constrcutor from the class/struct.
final class GenericClassAndStructConstructorReferenceBuilder: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() {
        let genericDeclarations = graph.declarations(ofKinds: [.class, .struct]).filter {
            $0.declarations.contains { $0.kind == .genericTypeParam }
        }

        for declaration in genericDeclarations {
            let constructors = declaration.declarations.filter { $0.kind == .functionConstructor }

            for constructor in constructors {
                for usr in constructor.usrs {
                    let reference = Reference(kind: .functionConstructor,
                                              usr: usr,
                                              location: declaration.location)
                    reference.name = constructor.name
                    reference.parent = declaration
                    graph.add(reference, from: declaration)
                }
            }
        }
    }
}
