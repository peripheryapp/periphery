import Configuration
import Foundation
import Shared

/// Builds references from implicit inherited initializers to the superclass initializer they inherit.
///
/// When a subclass inherits an initializer from its superclass, the index store records a relationship
/// from the superclass initializer to the subclass implicit initializer, but not the inverse. This mutator
/// adds the inverse reference so that when the implicit initializer is used, the superclass initializer
/// is also marked as used.
final class InheritedImplicitInitializerReferenceBuilder: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration _: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
    }

    func mutate() {
        for classDecl in graph.declarations(ofKind: .class) {
            // Find explicit (non-implicit) initializers in this class
            let explicitInitializers = classDecl.declarations.filter {
                $0.kind == .functionConstructor && !$0.isImplicit
            }

            for explicitInit in explicitInitializers {
                // Check if this initializer has related references to implicit initializers in subclasses
                for relatedRef in explicitInit.related {
                    guard relatedRef.kind == .functionConstructor else { continue }

                    // Find the declaration this related reference points to
                    guard let implicitInit = graph.declaration(withUsr: relatedRef.usr),
                          implicitInit.isImplicit,
                          implicitInit.kind == .functionConstructor
                    else { continue }

                    // Add the inverse reference: implicit init -> explicit init
                    for usr in explicitInit.usrs {
                        let reference = Reference(
                            kind: .functionConstructor,
                            usr: usr,
                            location: implicitInit.location,
                            isRelated: true
                        )
                        reference.name = explicitInit.name
                        reference.parent = implicitInit
                        graph.add(reference, from: implicitInit)
                    }
                }
            }
        }
    }
}
