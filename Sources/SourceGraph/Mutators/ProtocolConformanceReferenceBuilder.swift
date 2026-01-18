import Configuration
import Foundation
import Shared

/// Inverts references between protocol requirements and their conforming implementations.
///
/// The Swift indexer creates references from conforming declarations TO protocol requirements
/// (e.g., `S.foo -> P.foo`). We invert these so protocol requirements reference their implementations
/// (`P.foo -> S.foo`). This ensures that when code calls a method on a protocol type, the conforming
/// implementations are transitively marked as used.
final class ProtocolConformanceReferenceBuilder: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration _: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
    }

    func mutate() {
        let nonInvertibleReferences = referenceConformingDeclarationsImplementedInSuperclass()
        // These nonInvertibleReferences were just created, and are already in their correct place.
        // We're passing them here to the next step so that they're not inverted.
        invertReferencesFromProtocolToDeclaration(nonInvertibleReferences)
    }

    // MARK: - Private

    private func referenceConformingDeclarationsImplementedInSuperclass() -> Set<Reference> {
        let protocols = graph.declarations(ofKind: .protocol)

        let newReferences = Set(JobPool(jobs: Array(protocols)).flatMap { [graph] proto in
            var result: [Reference] = []
            // Find all classes that implement this protocol.
            let conformingClasses = graph.references(to: proto)
                .reduce(into: Set<Declaration>()) { result, ref in
                    if ref.kind == .related, let parent = ref.parent, parent.kind == .class {
                        result.insert(parent)
                    }
                }

            for conformingClass in conformingClasses {
                // Find declarations defined by the protocol not defined in the class.
                let unimplementedProtoDecls = proto.declarations.filter { protoDeclaration in
                    !conformingClass.declarations.contains { clsDeclaration in
                        protoDeclaration.kind == clsDeclaration.kind &&
                            protoDeclaration.name == clsDeclaration.name
                    }
                }

                if !unimplementedProtoDecls.isEmpty {
                    // Find all superclasses.
                    let superclassDecls = graph.inheritedTypeReferences(of: conformingClass)
                        .filter { $0.declarationKind == .class }
                        .compactMap { graph.declaration(withUsr: $0.usr) }
                        .flatMap(\.declarations)

                    for unimplementedProtoDecl in unimplementedProtoDecls {
                        // Find the implementation declaration in a superclass.
                        let declInSuperclass = superclassDecls.first {
                            $0.kind == unimplementedProtoDecl.kind &&
                                $0.name == unimplementedProtoDecl.name
                        }

                        if let declInSuperclass {
                            // Build a reference from the protocol declarations to the
                            // declaration implemented by the superclass.
                            for usr in declInSuperclass.usrs {
                                let reference = Reference(
                                    kind: .related,
                                    declarationKind: declInSuperclass.kind,
                                    usr: usr,
                                    location: declInSuperclass.location
                                )
                                reference.name = declInSuperclass.name
                                reference.parent = unimplementedProtoDecl
                                result.append(reference)
                            }
                        }
                    }
                }
            }
            return result
        })
        // Perform mutations on the graph based on the calculated references
        for newReference in newReferences {
            if let parent = newReference.parent {
                graph.add(newReference, from: parent)
            }
        }

        return newReferences
    }

    private func invertReferencesFromProtocolToDeclaration(_ nonInvertableReferences: Set<Reference>) {
        let relatedReferences = graph.allReferences.filter { $0.kind == .related && $0.declarationKind.isProtocolMemberConformingKind }

        for relatedReference in relatedReferences.subtracting(nonInvertableReferences) {
            guard let conformingDeclaration = relatedReference.parent
            else { continue }

            var equivalentDeclarationKinds = [relatedReference.declarationKind]

            // A conforming declaration can be declared either 'class' or 'static', whereas
            // protocol members can only be declared as 'static'.
            if relatedReference.declarationKind == .functionMethodStatic {
                equivalentDeclarationKinds.append(.functionMethodClass)
            } else if relatedReference.declarationKind == .functionMethodClass {
                equivalentDeclarationKinds.append(.functionMethodStatic)
            } else if relatedReference.declarationKind == .varStatic {
                equivalentDeclarationKinds.append(.varClass)
            } else if relatedReference.declarationKind == .varClass {
                equivalentDeclarationKinds.append(.varStatic)
            } else if relatedReference.declarationKind == .associatedtype {
                equivalentDeclarationKinds.append(contentsOf: Declaration.Kind.concreteTypeDeclarableKinds)
            }

            guard equivalentDeclarationKinds.contains(conformingDeclaration.kind),
                  conformingDeclaration.name == relatedReference.name else { continue }

            if let protocolDeclaration = graph.declaration(withUsr: relatedReference.usr) {
                // Invert the related reference such that instead of the conforming declaration
                // referencing the declaration within the protocol, the protocol declaration
                // now references the conforming declaration.

                // Note: we don't remove this reference if the conforming declaration is a default
                // implementation declared within an extension.
                if !conformingDeclaration.isDeclaredInExtension(kind: .extensionProtocol) {
                    graph.remove(relatedReference)
                }

                for usr in conformingDeclaration.usrs {
                    let newReference = Reference(
                        kind: .related,
                        declarationKind: relatedReference.declarationKind,
                        usr: usr,
                        location: relatedReference.location
                    )
                    newReference.name = relatedReference.name
                    newReference.parent = protocolDeclaration
                    graph.add(newReference, from: protocolDeclaration)
                }
            } else {
                graph.markRetained(conformingDeclaration)
            }
        }
    }
}
