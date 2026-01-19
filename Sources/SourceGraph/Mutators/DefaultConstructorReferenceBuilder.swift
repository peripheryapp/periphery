import Configuration
import Foundation
import Shared

final class DefaultConstructorReferenceBuilder: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration _: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
    }

    func mutate() {
        referenceDefaultConstructors()
        referenceDestructors()
    }

    // MARK: - Private

    private func referenceDefaultConstructors() {
        let defaultConstructors = graph.declarations(ofKind: .functionConstructor).filter {
            // Some initializers are referenced internally, e.g by JSONEncoder/Decoder so we need
            // to assume they are referenced.
            $0.name == "init()" || $0.isImplicit
        }

        for constructor in defaultConstructors {
            if let parent = constructor.parent {
                for usr in constructor.usrs {
                    let reference = Reference(
                        kind: .normal,
                        declarationKind: .functionConstructor,
                        usr: usr,
                        location: parent.location
                    )
                    reference.name = constructor.name
                    reference.parent = parent
                    graph.add(reference, from: parent)
                }
            }
        }
    }

    private func referenceDestructors() {
        for destructor in graph.declarations(ofKind: .functionDestructor) {
            if let parent = destructor.parent {
                for usr in destructor.usrs {
                    let reference = Reference(
                        kind: .normal,
                        declarationKind: .functionDestructor,
                        usr: usr,
                        location: parent.location
                    )
                    reference.name = destructor.name
                    reference.parent = parent
                    graph.add(reference, from: parent)
                }
            }
        }
    }
}
