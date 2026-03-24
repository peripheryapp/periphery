import Configuration
import Foundation
import Shared

/// https://github.com/apple/swift/issues/54532
/// Constructors on a class/struct with generic type parameters are not referenced despite being used.
/// We therefore must reference the constructor from the class/struct.
final class GenericClassAndStructConstructorReferenceBuilder: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration _: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
    }

    func mutate() {
        let genericDeclarations = graph.declarations(ofKinds: [.class, .struct]).filter {
            $0.declarations.contains { $0.kind == .genericTypeParam }
        }

        for declaration in genericDeclarations {
            let constructors = declaration.declarations.filter { $0.kind == .functionConstructor }

            for constructor in constructors {
                for usrID in constructor.usrIDs {
                    let usr = graph.usrInterner.string(for: usrID)
                    let reference = Reference(
                        name: constructor.name,
                        kind: .normal,
                        declarationKind: .functionConstructor,
                        usrID: usrID,
                        usr: usr,
                        location: declaration.location
                    )
                    reference.parent = declaration
                    graph.add(reference, from: declaration)
                }
            }
        }
    }
}
