import Foundation

final class DefaultConstructorReferenceBuilder: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() {
        referenceDefaultConstructors()
        referenceDestructors()
    }

    // MARK: - Private

    private func referenceDefaultConstructors() {
        let defaultConstructors = graph.declarations(ofKind: .functionConstructor).filter {
            $0.name == "init()" || $0.name == nil
        }

        defaultConstructors.forEach { constructor in
            if let parent = constructor.parent as? Declaration {
                let reference = Reference(kind: .functionConstructor,
                                          usr: constructor.usr,
                                          location: parent.location)
                reference.name = constructor.name
                reference.parent = parent
                graph.add(reference, from: parent)
            }
        }
    }

    private func referenceDestructors() {
        graph.declarations(ofKind: .functionDestructor).forEach { destructor in
            if let parent = destructor.parent as? Declaration {
                let reference = Reference(kind: .functionDestructor,
                                          usr: destructor.usr,
                                          location: parent.location)
                reference.name = destructor.name
                reference.parent = parent
                graph.add(reference, from: parent)
            }
        }
    }
}
