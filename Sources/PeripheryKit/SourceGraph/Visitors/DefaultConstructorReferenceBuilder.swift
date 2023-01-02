import Foundation

final class DefaultConstructorReferenceBuilder: SourceGraphMutator {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func mutate() {
        referenceDefaultConstructors()
        referenceDestructors()
    }

    // MARK: - Private

    private func referenceDefaultConstructors() {
        let defaultConstructors = graph.declarations(ofKind: .functionConstructor).filter {
            $0.name == "init()"
        }

        defaultConstructors.forEach { constructor in
            if let parent = constructor.parent {
                for usr in constructor.usrs {
                    let reference = Reference(kind: .functionConstructor,
                                              usr: usr,
                                              location: parent.location)
                    reference.name = constructor.name
                    reference.parent = parent
                    graph.add(reference, from: parent)
                }
            }
        }
    }

    private func referenceDestructors() {
        graph.declarations(ofKind: .functionDestructor).forEach { destructor in
            if let parent = destructor.parent {
                for usr in destructor.usrs {
                    let reference = Reference(kind: .functionDestructor,
                                              usr: usr,
                                              location: parent.location)
                    reference.name = destructor.name
                    reference.parent = parent
                    graph.add(reference, from: parent)
                }
            }
        }
    }
}
