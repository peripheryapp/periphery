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
                for usrID in constructor.usrIDs {
                    let usr = graph.usrInterner.string(for: usrID)
                    let reference = Reference(
                        name: constructor.name,
                        kind: .normal,
                        declarationKind: .functionConstructor,
                        usrID: usrID,
                        usr: usr,
                        location: parent.location
                    )
                    reference.parent = parent
                    graph.add(reference, from: parent)
                }
            }
        }
    }

    private func referenceDestructors() {
        for destructor in graph.declarations(ofKind: .functionDestructor) {
            if let parent = destructor.parent {
                for usrID in destructor.usrIDs {
                    let usr = graph.usrInterner.string(for: usrID)
                    let reference = Reference(
                        name: destructor.name,
                        kind: .normal,
                        declarationKind: .functionDestructor,
                        usrID: usrID,
                        usr: usr,
                        location: parent.location
                    )
                    reference.parent = parent
                    graph.add(reference, from: parent)
                }
            }
        }
    }
}
